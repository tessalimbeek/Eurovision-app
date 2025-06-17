// composables/useChatNotifications.ts
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../supabase'
import type { RealtimeChannel } from '@supabase/supabase-js'

// Explicit type for unreadCount
export const unreadCount = ref<number>(0)

let globalSubscription: RealtimeChannel | null = null
let currentUser: { id: string } | null = null
let currentUserGroupId: string | null = null

export function useChatNotifications() {
  const route = useRoute()

  async function initializeNotifications(): Promise<void> {
    if (globalSubscription) return // Already initialized

    const {
      data: { user }
    } = await supabase.auth.getUser()
    if (!user) return

    currentUser = user

    const { data: userGroupId, error } = await supabase.rpc('get_user_group_id', { user_id: user.id })

    if (error || !userGroupId) return
    currentUserGroupId = userGroupId

    globalSubscription = supabase
      .channel('global-chat-notifications')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages'
        },
        (payload) => {
        const message = payload.new as {
            group_id: string
            sender_id: string
        }

        if (
            currentUser &&
            message.group_id === currentUserGroupId &&
            message.sender_id !== currentUser.id &&
            route.path !== '/chat'
        ) {
            unreadCount.value++
        }
        }
      )
      .subscribe()
  }

  function clearUnreadCount(): void {
    unreadCount.value = 0
  }

  function cleanup(): void {
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
