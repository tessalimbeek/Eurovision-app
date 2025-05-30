<script setup lang="ts">
import { ref, onUnmounted, computed } from 'vue'
import { supabase } from '@/supabase'
import Navigation from '@/components/Navigation.vue'
import { useRoute } from 'vue-router'

import { useChatNotifications } from '@/composables/useChatNotifications'

const { cleanup } = useChatNotifications()

const isLoggedIn = ref(false)
const route = useRoute()

async function checkUser() {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  isLoggedIn.value = !!user
}

checkUser()

const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
  isLoggedIn.value = !!session?.user
})

onUnmounted(() => {
  authListener.subscription.unsubscribe()
  cleanup()
})

const showNavigation = computed(() => isLoggedIn.value && route.path !== '/')
</script>

<template>
  <RouterView />
  <Navigation v-if="showNavigation" />
</template>
