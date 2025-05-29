<template>
    <main>

        <img src="/pwa-512x512.png">

        <h1>Join a Room</h1>
  
        <form @submit.prevent="handleLogin">
          <input
            v-model="name"
            type="text"
            placeholder="Your name"
            required
          />
          <input
            v-model="email"
            type="email"
            placeholder="Email"
            required
          />
          <input
            v-model="inviteCode"
            type="text"
            placeholder="Room code"
            required
            autocapitalize="none"
            spellcheck="false"
            autocomplete="off"
          />
  
          <button
            type="submit"
          >
            Join Room
          </button>
        </form>
  
        <p v-if="error" class="text-red-500 text-sm mt-4 text-center">{{ error }}</p>


    </main>
  </template>


<style scoped>

form{
    display: flex;
    flex-direction: column;
}

input {
  font-size: 16px;
}

input[type=text], input[type=email] {
  width: 100%;
  padding: 12px 20px;
  margin: 8px 0;
  box-sizing: border-box;
}

h1{
    text-align: center;
}
img{
    width: 70%;
    display: block;
    margin: 0 auto;
}

</style>
  
  <script setup>
  import { ref } from 'vue'
  import { useRouter, useRoute } from 'vue-router'
  import { supabase } from '../supabase'
  import { initChatSubscription } from '../composables/chatState' // ← add this
  
  const name = ref('')
  const email = ref('')
  const inviteCode = ref('')
  const error = ref(null)
  const router = useRouter()
  const route = useRoute()
  
  const handleLogin = async () => {
  error.value = null

  const { data: group, error: groupError } = await supabase
    .from('groups')
    .select('id')
    .eq('invite_code', inviteCode.value.trim())
    .single()

    console.log('groupError:', groupError)
    console.log('group:', group)

  if (groupError || !group) {
    error.value = 'Invalid room code.'
    return
  }

  const password = email.value // consistent password

  // Sign up
  let { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email: email.value,
    password,
  })

  let user = signUpData?.user

  // Sign in fallback
  if (!user && signUpError?.message.includes('User already registered')) {
    console.log("sign in")
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password,
    })
    if (signInError) {
      error.value = signInError.message
      return
    }
    user = signInData.user
  }

  if (!user) {
    error.value = 'Authentication failed.'
    return
  }

  const { data: existingProfile, error: fetchError } = await supabase
    .from('users')
    .select('id')
    .eq('id', user.id)
    .maybeSingle()

  if (fetchError) {
    error.value = fetchError.message
    return
  }

  if (!existingProfile) {
    const { error: insertError } = await supabase.from('users').insert({
      id: user.id,
      name: name.value.trim(),
      group_id: group.id,
    })

    if (insertError) {
      error.value = insertError.message
      return
    }
  }

  initChatSubscription(group.id, route.path)
  router.push('/home')
}


  </script>
  