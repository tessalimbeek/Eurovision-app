<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../supabase'
import { nextTick } from 'vue'
import { unreadCount } from '../composables/useChatNotifications'

const user = ref(null)
const messages = ref([])
const newMessage = ref('')
const userMap = ref({})
let chatSubscription = null // Separate subscription for chat updates

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

function scrollToBottom() {
  nextTick(() => {
    const chatBoard = document.querySelector('.chat__conversation-board')
    if (chatBoard) {
      chatBoard.scrollTop = chatBoard.scrollHeight
    }
  })
}

async function fetchInitialData() {
  const {
    data: { user: authUser },
  } = await supabase.auth.getUser()
  if (!authUser) return
  user.value = authUser

  // Use the get_user_group_id function instead of direct query
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
        let avatar = null

        if (u.avatar_url) {
          const { data: signed, error } = await supabase.storage
            .from('avatars')
            .createSignedUrl(u.avatar_url, 60 * 60)

          if (!error && signed?.signedUrl) {
            avatar = signed.signedUrl
          }
        }

        return [u.id, { name: u.name, avatar_url: avatar }]
      }),
    ),
  )

chatSubscription = supabase
    .channel('chat-live-updates') // Different channel name
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'messages'
    }, async payload => {
      if (payload.new.group_id === userGroupId) {
        messages.value.push(payload.new)
        
        // Update userMap if we haven't seen this sender before
        if (!userMap.value[payload.new.sender_id]) {
          const { data: newUser } = await supabase
            .from('users')
            .select('id, name, avatar_url')
            .eq('id', payload.new.sender_id)
            .single()

          if (newUser) {
            let avatar = null
            if (newUser.avatar_url) {
              const { data: signed, error } = await supabase
                .storage
                .from('avatars')
                .createSignedUrl(newUser.avatar_url, 60 * 60)

              if (!error && signed?.signedUrl) {
                avatar = signed.signedUrl
              }
            }
            userMap.value[newUser.id] = { name: newUser.name, avatar_url: avatar }
          }
        }
        
        // Always scroll to bottom for new messages when on chat page
        nextTick(() => {
          scrollToBottom()
        })
      }
    })
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

  // Get user's group_id before sending message
  const { data: userGroupId, error: groupError } = await supabase.rpc('get_user_group_id', {
    user_id: user.value.id,
  })

  if (groupError || !userGroupId) {
    console.error('Error fetching user group for message:', groupError)
    return
  }

  // Insert message with explicit group_id and sender_id
  const { error } = await supabase.from('messages').insert([
    {
      content,
      group_id: userGroupId,
      sender_id: user.value.id,
    },
  ])

  if (error) {
    console.error('Error sending message:', error)
    // Restore the message content if there was an error
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

          <div class="chat__message-bubble">
            {{ msg.content }}
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
          autocomplete="off"
          autocorrect="on"
          autocapitalize="sentences"
          spellcheck="true"
        />
        <button class="chat__send-button" @click="sendMessage" aria-label="Send message">
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

.chat__message-container.sent .chat__message-bubble {
  background: var(--chat-bubble-sent-background, #0b93f6);
  color: white;
  border-bottom-right-radius: 4px;
  border-bottom-left-radius: 16px;
  border-top-left-radius: 16px;
  border-top-right-radius: 16px;
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
