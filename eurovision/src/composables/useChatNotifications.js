// import { ref } from 'vue'
// import { supabase } from '../supabase'

// export const unreadCount = ref(0)

// const user = ref(null)
// const messages = ref([])
// const newMessage = ref('')
// const userMap = ref({})
// let subscription = null
// const defaultAvatar = '/default-avatar.png'

// const inputRef = ref(null)

// export function initChatSubscription(groupId, currentPath) {
//   if (subscription) return

// //   subscription = supabase
// //     .channel('group-chat')
// //     .on(
// //       'postgres_changes',
// //       {
// //         event: 'INSERT',
// //         schema: 'public',
// //         table: 'messages',
// //       },
// //       (payload) => {
// //         if (payload.new.group_id === groupId) {
// //           if (currentPath !== '/chat') {
// //             unreadCount.value++
// //           }
// //         }
// //       }
// //     )
// //     .subscribe()
// subscription = supabase
//     .channel('group-chat')
//     .on('postgres_changes', {
//       event: 'INSERT',
//       schema: 'public',
//       table: 'messages'
//     }, async payload => {
//       if (payload.new.group_id === groupId) {
//         messages.value.push(payload.new)
        
//         // Update userMap if we haven't seen this sender before
//         if (!userMap.value[payload.new.sender_id]) {
//           const { data: newUser } = await supabase
//             .from('users')
//             .select('id, name, avatar_url')
//             .eq('id', payload.new.sender_id)
//             .single()

//           if (newUser) {
//             let avatar = null
//             if (newUser.avatar_url) {
//               const { data: signed, error } = await supabase
//                 .storage
//                 .from('avatars')
//                 .createSignedUrl(newUser.avatar_url, 60 * 60)

//               if (!error && signed?.signedUrl) {
//                 avatar = signed.signedUrl
//               }
//             }
//             userMap.value[newUser.id] = { name: newUser.name, avatar_url: avatar }
//           }
//         }
        
//         if (currentPath !== '/chat') {
//           unreadCount.value++
//           console.log(unreadCount)
//         } else if (payload.new.sender_id === user.value.id) {
//           // Only scroll if current user sent the message
//           nextTick(() => {
//             scrollToBottom()
//           })
//         }
//       }
//     })
//     .subscribe()
// }

// export function clearChatSubscription() {
//   if (subscription) {
//     supabase.removeChannel(subscription)
//     subscription = null
//   }
// }


// composables/useChatNotifications.js
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../supabase'

export const unreadCount = ref(0)

let globalSubscription = null
let currentUser = null
let currentUserGroupId = null

export function useChatNotifications() {
  const route = useRoute()

  async function initializeNotifications() {
    if (globalSubscription) return // Already initialized

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    currentUser = user
    const { data: userGroupId } = await supabase
      .rpc('get_user_group_id', { user_id: user.id })

    if (!userGroupId) return
    currentUserGroupId = userGroupId

    globalSubscription = supabase
    .channel('global-chat-notifications')
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'messages'
    }, payload => {
      // Only increment unread count when NOT on chat page
      if (payload.new.group_id === currentUserGroupId && 
          payload.new.sender_id !== currentUser.id && 
          route.path !== '/chat') {
        unreadCount.value++
      }
    })
    .subscribe()
  }

  function clearUnreadCount() {
    unreadCount.value = 0
  }

  function cleanup() {
    if (globalSubscription) {
      supabase.removeChannel(globalSubscription)
      globalSubscription = null
    }
  }

  return {
    unreadCount,
    initializeNotifications,
    clearUnreadCount,
    cleanup
  }
}