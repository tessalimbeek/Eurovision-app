import { ref } from 'vue'
import { supabase } from '../supabase'

export const unreadCount = ref(0)

let subscription = null

export function initChatSubscription(groupId, currentPath) {
  if (subscription) return

  subscription = supabase
    .channel('group-chat')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
      },
      (payload) => {
        if (payload.new.group_id === groupId) {
          if (currentPath !== '/chat') {
            unreadCount.value++
          }
        }
      }
    )
    .subscribe()
}

export function clearChatSubscription() {
  if (subscription) {
    supabase.removeChannel(subscription)
    subscription = null
  }
}
