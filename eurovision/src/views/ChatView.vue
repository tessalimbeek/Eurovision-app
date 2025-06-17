<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { supabase } from '../supabase'
import { unreadCount } from '@/composables/useChatNotifications'

const user = ref(null)
const messages = ref([])
const newMessage = ref('')
const userMap = ref({})
const fileInputRef = ref(null)
let chatSubscription = null

const defaultAvatar = '/default-avatar.png'
const inputRef = ref(null)

function dismissKeyboardOnScroll() {
  const chatBoard = document.querySelector('.chat__conversation-board')
  if (!chatBoard) return

  chatBoard.addEventListener('scroll', () => {
    if (document.activeElement === inputRef.value) {
      inputRef.value.blur()
    }
  })
}

function triggerFileInput() {
  fileInputRef.value?.click()
}

function scrollToBottom() {
  nextTick(() => {
    const chatBoard = document.querySelector('.chat__conversation-board')
    if (chatBoard) {
      chatBoard.scrollTop = chatBoard.scrollHeight
    }
  })
}

async function handleFileUpload(event) {
  console.log('File upload triggered', event.target.files)

  const file = event.target.files[0]
  if (!file || !user.value) return

  //   const fileName = `${user.value.id}/${Date.now()}-${file.name}`
  const fileName = `${userGroupId}/${user.value.id}-${Date.now()}-${file.name}`

  // Upload image to Supabase
  const uploadResult = await supabase.storage.from('chat-images').upload(fileName, file)

  if (uploadResult.error) {
    console.error('Image upload failed:', uploadResult.error)
    return
  }

  const imagePath = uploadResult.data.path

  // Create signed URL
  const signedUrlResult = await supabase.storage
    .from('chat-images')
    .createSignedUrl(imagePath, 60 * 60 * 24 * 7)

  if (signedUrlResult.error || !signedUrlResult.data?.signedUrl) {
    console.error('Failed to get signed URL:', signedUrlResult.error)
    return
  }

  const signedUrl = signedUrlResult.data.signedUrl

  // Get user group
  const { data: userGroupId, error: groupError } = await supabase.rpc('get_user_group_id', {
    user_id: user.value.id,
  })

  if (groupError || !userGroupId) {
    console.error('Error fetching user group for image:', groupError)
    return
  }

  // Insert message with image
  const { error: insertError } = await supabase.from('messages').insert([
    {
      content: '',
      sender_id: user.value.id,
      group_id: userGroupId,
      is_image: true,
      image_url: signedUrl,
    },
  ])

  if (insertError) {
    console.error('Error inserting image message:', insertError)
  }

  // Reset file input
  event.target.value = ''
}

async function fetchAndCacheAvatar(userId, signedUrl) {
  try {
    const response = await fetch(signedUrl)
    const blob = await response.blob()
    const reader = new FileReader()

    return new Promise((resolve) => {
      reader.onloadend = () => {
        const base64Data = reader.result
        localStorage.setItem(`avatar_${userId}`, base64Data)
        resolve(base64Data)
      }
      reader.readAsDataURL(blob)
    })
  } catch (err) {
    console.warn(`Failed to cache avatar for user ${userId}`, err)
    return null
  }
}

async function fetchInitialData() {
  const {
    data: { user: authUser },
  } = await supabase.auth.getUser()
  if (!authUser) return
  user.value = authUser

  const { data: userGroupId, error: groupError } = await supabase.rpc('get_user_group_id', {
    user_id: user.value.id,
  })

  if (groupError || !userGroupId) {
    console.error('Error fetching user group:', groupError)
    return
  }

  const { data: initialMessages } = await supabase
    .from('messages')
    .select('*')
    .eq('group_id', userGroupId)
    .order('created_at')

  messages.value = initialMessages || []
  scrollToBottom()

  const senderIds = [...new Set(messages.value.map((m) => m.sender_id))]

  const { data: users } = await supabase
    .from('users')
    .select('id, name, avatar_url')
    .in('id', senderIds)

  userMap.value = Object.fromEntries(
    await Promise.all(
      users.map(async (u) => {
        const cached = localStorage.getItem(`avatar_${u.id}`)
        if (cached) {
          return [u.id, { name: u.name, avatar_url: cached }]
        }

        let avatar = null
        if (u.avatar_url) {
          const { data: signed, error } = await supabase.storage
            .from('avatars')
            .createSignedUrl(u.avatar_url, 60 * 60)

          if (!error && signed?.signedUrl) {
            avatar = await fetchAndCacheAvatar(u.id, signed.signedUrl)
          }
        }

        return [u.id, { name: u.name, avatar_url: avatar }]
      }),
    ),
  )

  chatSubscription = supabase
    .channel('chat-live-updates')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
      },
      async (payload) => {
        if (payload.new.group_id === userGroupId) {
          messages.value.push(payload.new)

          if (!userMap.value[payload.new.sender_id]) {
            const { data: newUser } = await supabase
              .from('users')
              .select('id, name, avatar_url')
              .eq('id', payload.new.sender_id)
              .single()

            if (newUser) {
              const cached = localStorage.getItem(`avatar_${newUser.id}`)
              let avatar = cached

              if (!cached && newUser.avatar_url) {
                const { data: signed, error } = await supabase.storage
                  .from('avatars')
                  .createSignedUrl(newUser.avatar_url, 60 * 60)

                if (!error && signed?.signedUrl) {
                  avatar = await fetchAndCacheAvatar(newUser.id, signed.signedUrl)
                }
              }

              userMap.value[newUser.id] = {
                name: newUser.name,
                avatar_url: avatar,
              }
            }
          }

          nextTick(() => scrollToBottom())
        }
      },
    )
    .subscribe()
}

function getUserName(id) {
  return userMap.value[id]?.name || 'Someone'
}

function getAvatarUrl(id) {
  return userMap.value[id]?.avatar_url || defaultAvatar
}

async function sendMessage() {
  if (!user.value || !newMessage.value.trim()) return

  const content = newMessage.value.trim()
  newMessage.value = ''

  const { data: userGroupId, error: groupError } = await supabase.rpc('get_user_group_id', {
    user_id: user.value.id,
  })

  if (groupError || !userGroupId) {
    console.error('Error fetching user group for message:', groupError)
    return
  }

  const { error } = await supabase.from('messages').insert([
    {
      content,
      group_id: userGroupId,
      sender_id: user.value.id,
    },
  ])

  if (error) {
    console.error('Error sending message:', error)
    newMessage.value = content
  }
}

onMounted(() => {
  unreadCount.value = 0
  fetchInitialData()
  dismissKeyboardOnScroll()
})

onUnmounted(() => {
  if (chatSubscription) {
    supabase.removeChannel(chatSubscription)
  }
  const chatBoard = document.querySelector('.chat__conversation-board')
  if (chatBoard) {
    chatBoard.removeEventListener('scroll', dismissKeyboardOnScroll)
  }
})
</script>

<template>
  <main class="chat-layout">
    <div id="chat" class="--dark-theme">
      <div class="chat__conversation-board" ref="chatBoard">
        <div
          v-for="(msg, index) in messages"
          :key="msg.id"
          :class="['chat__message-container', user?.id === msg.sender_id ? 'sent' : 'received']"
        >
          <div
            class="chat__message-header"
            v-if="index === 0 || messages[index - 1].sender_id !== msg.sender_id"
          >
            <img
              class="chat__avatar"
              :src="getAvatarUrl(msg.sender_id)"
              :alt="getUserName(msg.sender_id)"
              loading="lazy"
              width="32"
              height="32"
            />
            <span class="chat__username">{{ getUserName(msg.sender_id) }}</span>
          </div>

          <div
            class="chat__message-bubble"
            :class="{ 'chat__message-bubble--image': msg.is_image && msg.image_url }"
          >
            <template v-if="msg.is_image && msg.image_url">
              <img :src="msg.image_url" alt="image" class="chat__image-message" loading="lazy" />
            </template>
            <template v-else>
              {{ msg.content }}
            </template>
          </div>
        </div>
      </div>
      <div class="chat__input-panel">
        <input
          ref="inputRef"
          class="chat__input"
          type="text"
          placeholder="Type a message..."
          v-model="newMessage"
          @keyup.enter="sendMessage"
        />
        <input type="file" ref="fileInputRef" @change="handleFileUpload" accept="image/*" hidden />

        <button
          class="chat__send-button"
          @click="triggerFileInput"
          aria-label="Upload image"
          v-show="newMessage.trim().length === 0"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="size-6"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M6.827 6.175A2.31 2.31 0 0 1 5.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 0 0-1.134-.175 2.31 2.31 0 0 1-1.64-1.055l-.822-1.316a2.192 2.192 0 0 0-1.736-1.039 48.774 48.774 0 0 0-5.232 0 2.192 2.192 0 0 0-1.736 1.039l-.821 1.316Z"
            />
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M16.5 12.75a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0ZM18.75 10.5h.008v.008h-.008V10.5Z"
            />
          </svg>
        </button>

        <button
          class="chat__send-button"
          @click="sendMessage"
          aria-label="Send message"
          v-show="newMessage.trim().length > 0"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            width="20"
            height="20"
            fill="white"
            aria-hidden="true"
            focusable="false"
          >
            <path
              d="M1.94607 9.31543C1.42353 9.14125 1.4194 8.86022 1.95682 8.68108L21.043 2.31901C21.5715 2.14285 21.8746 2.43866 21.7265 2.95694L16.2733 22.0432C16.1223 22.5716 15.8177 22.59 15.5944 22.0876L11.9999 14L17.9999 6.00005L9.99992 12L1.94607 9.31543Z"
            />
          </svg>
        </button>
      </div>
    </div>
  </main>
</template>

<style scoped>
main {
  padding: 0;
}
.chat-layout {
  display: flex;
  flex-direction: column;
  height: 100dvh;
  background: var(--chat-background);
  font-family: 'Lato', sans-serif;
  color: var(--chat-text-color);
}

#chat {
  max-width: 600px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  height: 100%;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 0 8px rgba(0, 0, 0, 0.15);
}

.chat__conversation-board {
  flex-grow: 1;
  overflow-y: auto;
  padding: 20px 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  scroll-behavior: smooth;
}

.chat__message-container {
  max-width: 75%;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.chat__image-message {
  max-width: 100%;
  border-radius: 12px;
  object-fit: contain;
}

.chat__message-container.sent {
  align-self: flex-end;
  text-align: right;
}

.chat__message-container.received {
  align-self: flex-start;
  text-align: left;
}

.chat__message-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
}

.chat__message-container.sent .chat__message-header {
  flex-direction: row-reverse;
}

.chat__avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  background: #ccc;
}

.chat__username {
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 120px;
}

.chat__message-bubble {
  background: var(--chat-bubble-background);
  padding: 10px 14px;
  border-radius: 16px;
  font-size: 14px;
  line-height: 1.3;
  word-wrap: break-word;
  box-shadow: 0 1px 3px rgb(0 0 0 / 0.1);
}

.chat__message-bubble--image {
  padding: 2px;
  background: transparent;
  box-shadow: none;
}

.chat__message-container.sent .chat__message-bubble {
  background: var(--chat-bubble-sent-background, #0b93f6);
  color: white;
  border-bottom-right-radius: 4px;
  border-bottom-left-radius: 16px;
  border-top-left-radius: 14px;
  border-top-right-radius: 14px;
}

.chat__message-container.received .chat__message-bubble {
  background: var(--chat-bubble-received-background, #e5e5ea);
  color: #000;
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 16px;
  border-top-left-radius: 16px;
  border-top-right-radius: 16px;
}

.chat__input-panel {
  display: flex;
  padding: 12px 16px;
  align-items: center;
  gap: 12px;
}

.chat__input {
  flex-grow: 1;
  border-radius: 20px;
  border: 1px solid #ccc;
  padding: 10px 16px;
  font-size: 16px;
  color: var(--chat-text-color);
  background: white;
  outline-offset: 2px;
}

.chat__input:focus {
  outline: none; /* Remove the default focus outline */
  box-shadow: none; /* Remove any focus shadow */
  border-color: transparent; /* Optional, if input has border */
}

.chat__send-button {
  background: var(--accent-color);
  border: none;
  border-radius: 50%;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.chat__send-button svg {
  width: 20px;
  height: 20px;
}

@media (max-width: 600px) {
  #chat {
    border-radius: 0;
    height: 100dvh;
    max-width: 100%;
    margin: 0;
  }
}
</style>
