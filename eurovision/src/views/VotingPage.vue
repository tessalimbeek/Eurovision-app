
<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { watch } from 'vue'

const myVote = ref({ song: 0, performance: 0, vocals: 0, total_score: 0 })
const myNote = ref({ content: '' })
const groupVotes = ref([])
const user = ref(null)
const country = ref({})
const groupId = ref(null)
const userNames = ref({})
const route = useRoute()
const router = useRouter()
const countryId = ref(parseInt(route.params.countryId))
const currentPhase = ref(route.params.phase || 'semi1') // Get phase from route
const allCountries = ref([])
const prevCountryId = ref(null)
const nextCountryId = ref(null)
const userAvatars = ref({})
const avatarUrl = ref('')
const defaultAvatar = '/default-avatar.png'

function getFlagUrl(filename) {
  return new URL(`../assets/flags/${filename}`, import.meta.url).href
}

function isPhaseForFinal(phase) {
  return phase === 'final'
}

function goBack() {
  router.push(`/countries/semi1`)
}

function updateNavigationIds() {
  const index = allCountries.value.findIndex((c) => c.id === countryId.value)
  if (index !== -1) {
    prevCountryId.value = allCountries.value[index - 1]?.id || null
    nextCountryId.value = allCountries.value[index + 1]?.id || null
  }
}

async function loadCountriesForPhase(phase) {
  let query = supabase
    .from('countries')
    .select('id, semi_final, final, semi_running_order, final_running_order')

  // Filter and order based on phase
  switch (phase) {
    case 'semi1':
      query = query.eq('semi_final', 1).order('semi_running_order')
      break
    case 'semi2':
      query = query.eq('semi_final', 2).order('semi_running_order')
      break
    case 'final':
      query = query.eq('final', true).order('final_running_order')
      break
  }

  const { data } = await query
  return data || []
}

const generateSignedUrl = async (filePath) => {
  if (!filePath) return null

  try {
    const { data: signedUrlData, error: signedUrlError } = await supabase.storage
      .from('avatars')
      .createSignedUrl(filePath, 60 * 60) // 1 hour valid

    if (signedUrlError || !signedUrlData?.signedUrl) {
      console.warn('Failed to generate signed URL:', signedUrlError)
      return null
    }

    return signedUrlData.signedUrl
  } catch (error) {
    console.error('Error generating signed URL:', error)
    return null
  }
}

async function loadInitialData() {
  const { data: authData } = await supabase.auth.getUser()
  if (!authData?.user) return
  user.value = authData.user

  // Get profile
  const { data: profile } = await supabase
    .from('users')
    .select('group_id, name, avatar_url')
    .eq('id', user.value.id)
    .single()

  if (profile) groupId.value = profile.group_id

  // Handle avatar URL
  if (profile.avatar_url) {
    const signedUrl = await generateSignedUrl(profile.avatar_url)
    avatarUrl.value = signedUrl || defaultAvatar
  } else {
    avatarUrl.value = defaultAvatar
  }

  // Get country
  const { data: countryData } = await supabase
    .from('countries')
    .select('*')
    .eq('id', countryId.value)
    .single()

  if (countryData) {
    country.value = countryData

    // Load countries for the current phase (from route)
    allCountries.value = await loadCountriesForPhase(currentPhase.value)
    updateNavigationIds()
  }

  const isFinalVote = isPhaseForFinal(currentPhase.value)

  // Get user's vote for this phase
  const { data: voteData } = await supabase
    .from('votes')
    .select('*')
    .eq('user_id', user.value.id)
    .eq('country_id', countryId.value)
    .eq('is_final', isFinalVote)
    .single()

  if (voteData) myVote.value = voteData

  // Get user's note
  const { data: noteData } = await supabase
    .from('notes')
    .select('*')
    .eq('user_id', user.value.id)
    .eq('country_id', countryId.value)
    .single()
  if (noteData) myNote.value = noteData

  const { data: groupData } = await supabase
    .from('votes')
    .select('*')
    .eq('country_id', countryId.value)
    .eq('group_id', groupId.value)
    .eq('is_final', isFinalVote)
    .neq('user_id', user.value.id) // Exclude your own vote

  if (groupData) groupVotes.value = groupData

  // Load user names for the group
  await loadUserNames()
}

async function submitVote() {
  console.log('submit vote')
  const isFinalVote = isPhaseForFinal(currentPhase.value)
  const { song, performance, vocals, total_score } = myVote.value

  await supabase.from('votes').upsert({
    user_id: user.value.id,
    group_id: groupId.value,
    country_id: countryId.value,
    is_final: isFinalVote,
    song,
    performance,
    vocals,
    total_score,
    updated_at: new Date().toISOString(),
  })
}

async function submitNote() {
  await supabase.from('notes').upsert({
    user_id: user.value.id,
    group_id: groupId.value,
    country_id: countryId.value,
    content: myNote.value.content,
    updated_at: new Date().toISOString(),
  })
}

async function loadUserNames() {
  if (!groupId.value) return

  // get users of same group from supabase
  const { data: users } = await supabase
    .from('users')
    .select('id, name, avatar_url')
    .eq('group_id', groupId.value)

  if (users) {
    userNames.value = {}
    userAvatars.value = {}

    for (const u of users) {
      userNames.value[u.id] = u.name

      if (u.avatar_url) {
        const signedUrl = await generateSignedUrl(u.avatar_url)
        userAvatars.value[u.id] = signedUrl || defaultAvatar
      } else {
        userAvatars.value[u.id] = defaultAvatar
      }
    }
  }
}

function getUserName(userId) {
  if (userId === user.value.id) return 'You'
  return userNames.value[userId] || 'Unknown User'
}

// Watch for route change ( when clicking next/previous)
watch(
  () => route.params.countryId,
  async (newId, oldId) => {
    if (newId !== oldId) {
      myVote.value = { song: 0, performance: 0, vocals: 0 }
      myNote.value = { content: '' }
      groupVotes.value = []
      countryId.value = parseInt(newId)
      currentPhase.value = route.params.phase || 'semi1'
      await loadInitialData()
    }
  },
)

// when opening page, load inital data and have live votes channel
onMounted(() => {
  loadInitialData()

  supabase
    .channel('votes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'votes' }, (payload) => {
      const newVote = payload.new
      const isFinalVote = isPhaseForFinal(currentPhase.value)

      // Only update if it's for the current country, group, and phase
      if (
        newVote.country_id === countryId.value &&
        newVote.group_id === groupId.value &&
        newVote.is_final === isFinalVote
      ) {
        const idx = groupVotes.value.findIndex((v) => v.user_id === newVote.user_id)
        if (idx >= 0) groupVotes.value[idx] = newVote
        else groupVotes.value.push(newVote)
      }
    })
    .subscribe()
})
</script>

<template>
  <main>
    <div @click="goBack" class="button-back">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="1.5"
        class="w-6 h-6"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
      </svg>
    </div>

    <div class="nav-buttons">
      <RouterLink
        :to="{ name: 'VotingPage', params: { countryId: prevCountryId } }"
        v-if="prevCountryId"
      >
        <button class="previous">← Previous</button>
      </RouterLink>
      <div v-else style="visibility: hidden">
        <button class="previous">← Previous</button>
      </div>

      <RouterLink
        :to="{ name: 'VotingPage', params: { countryId: nextCountryId } }"
        v-if="nextCountryId"
      >
        <button class="next">Next →</button>
      </RouterLink>
      <div v-else style="visibility: hidden">
        <button class="next">Next →</button>
      </div>
    </div>

    <div class="country-voting">
      <div class="title">
        <img :src="getFlagUrl(country.flag)" :alt="country.name + ' flag'" class="flag" />
        <div class="country">
          <h2 class="country-name">{{ country.name }}</h2>
          <div class="artist">{{ country.artist_name }}</div>
          <div class="song-name">{{ country.song_name }}</div>
        </div>
      </div>

      <div class="voting-section">
        <div class="section-icon">
          <img src="../assets/music.png" />
          <label>Song: {{ myVote.song }}</label>
        </div>
        <input
          type="range"
          min="0"
          max="10"
          step="1"
          v-model.number="myVote.song"
          @change="submitVote"
          class="custom-slider"
        />

        <div class="section-icon">
          <img src="../assets/dress.png" />
          <label>Performace: {{ myVote.performance }}</label>
        </div>
        <input
          type="range"
          min="0"
          max="10"
          step="1"
          v-model.number="myVote.performance"
          @change="submitVote"
          class="custom-slider"
        />

        <div class="section-icon">
          <img src="../assets/microphone.png" />
          <label>Vocals: {{ myVote.vocals }}</label>
        </div>
        <input
          type="range"
          min="0"
          max="10"
          step="1"
          v-model.number="myVote.vocals"
          @change="submitVote"
          class="custom-slider"
        />

        <div class="section-icon">
          <img src="../assets/music.png" />
          <label>Total score: {{ myVote.total_score }}</label>
        </div>
        <input
          type="range"
          min="0"
          max="10"
          step="1"
          v-model.number="myVote.total_score"
          @change="submitVote"
          class="custom-slider"
        />
      </div>

      <div class="notes-section">
        <label>Notes:</label>
        <textarea
          v-model="myNote.content"
          @blur="submitNote"
          placeholder="Write your notes..."
        ></textarea>
      </div>

      <div class="live-votes">
        <h3>Group Votes</h3>
        <div class="group-votes">
          <div v-for="vote in groupVotes" :key="vote.user_id" class="group-vote">
            <div class="image">
              <img
                :src="userAvatars[vote.user_id] || defaultAvatar"
                alt="Profile Picture"
                class="profile"
              />
              <strong>{{ getUserName(vote.user_id) }}:</strong>
            </div>

            <div class="scores">
              <div class="element">
                <img src="../assets/music.png" />
                <label>Song: {{ vote.song }}</label>
              </div>

              <div class="element">
                <img src="../assets/dress.png" />
                <label>Performance: {{ vote.performance }}</label>
              </div>

              <div class="element">
                <img src="../assets/microphone.png" />
                <label>Vocals: {{ vote.vocals }}</label>
              </div>

              <div class="element">
                <img src="../assets/music.png" />
                <label>Total score: {{ vote.total_score }}</label>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>

<style scoped>
img {
  height: 100px;
}

.group-votes .image {
  display: flex;
  flex-direction: column;
}

.group-votes .scores img {
  height: 1.5em;
  width: auto;
}
.group-votes .scores {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.group-votes .scores .element {
  display: flex;
  flex-direction: row;
  gap: 20px;
}

.group-vote {
  display: flex;
  gap: 20px;
  margin-bottom: 30px;
}

.section-icon {
  display: flex;
  flex-direction: row;
  gap: 20px;
  margin-top: 1em;
}
.section-icon img {
  width: 20px;
  height: auto;
  object-fit: contain;
}

img.profile {
  width: 3rem;
  height: 3rem;
  object-fit: cover;
  border-radius: 50%;
}

.title {
  display: flex;
  flex-direction: row;
  text-transform: uppercase;
  gap: 20px;
}

.country-name {
  font-weight: 700;
  font-size: 1.5rem;
  margin-bottom: 0;
  text-transform: uppercase;
}
.artist,
.song-name {
  font-size: 0.85rem;
  opacity: 0.8;
}

input[type='range'] {
  width: 100%;
  color: var(--accent-color);
}

.country-voting {
  max-width: 600px;
  margin: auto;
  padding: 1em;
}

.voting-section label,
.notes-section label {
  display: block;
  font-weight: bold;
}

.custom-slider {
  -webkit-appearance: none;
  appearance: none;
  width: 100%;
  height: 8px;
  border-radius: 5px;
  background: linear-gradient(to right, #ff6b6b 0%, #feca57 50%, #48dbfb 100%);
  outline: none;
}

.custom-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #fff;
  border: 3px solid #333;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
}

.custom-slider::-moz-range-thumb {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #fff;
  border: 3px solid #333;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
}

.notes-section textarea {
  width: calc(100% - 1rem);
  min-height: 100px;
  margin-top: 0.25em;
  padding: 0.5em;
  font-size: 1rem;
  resize: vertical;
}

.nav-buttons {
  display: flex;
  justify-content: space-between;
  max-width: 600px;
  margin: 1em auto;
  padding: 0 1em;
}

.nav-buttons button {
  background-color: var(--accent-color);
  color: white;
  padding: 0.5em 1em;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
}

.nav-buttons button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
