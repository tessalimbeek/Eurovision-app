<script setup lang="ts">
import { onMounted } from 'vue'
import { supabase } from '@/supabase'

// onMounted(async () => {
//   const { data, error } = await supabase.auth.getUser()

//   if (error) {
//     console.error('Error getting user:', error.message)
//     return
//   }

//   if (data?.user) {
//     console.log('Logged-in user:', data.user)
//     // You can access: data.user.email, data.user.id, etc.
//   } else {
//     console.log('No user is logged in.')
//   }
// })
</script>

<template>
  <main>
    <h1>Hello Home page</h1>
  </main>
</template>
