<template>
    <main>
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
          <img
            :src="getFlagUrl(country.flag)"
            :alt="country.name + ' flag'"
            class="flag"
          />
          <div class="country">
            <h2 class="country-name">{{ country.name }}</h2>
            <div class="artist">{{ country.artist_name }}</div>
            <div class="song-name">{{ country.song_name }}</div>
          </div>     
        </div>
  
        <div class="voting-section">
          <label>Song: {{ myVote.song }}</label>
          <input
            type="range"
            min="0"
            max="10"
            step="1"
            v-model.number="myVote.song"
            @change="submitVote"
          />
  
          <label>Performance: {{ myVote.performance }}</label>
          <input
            type="range"
            min="0"
            max="10"
            step="1"
            v-model.number="myVote.performance"
            @change="submitVote"
          />
  
          <label>Vocals: {{ myVote.vocals }}</label>
          <input
            type="range"
            min="0"
            max="10"
            step="1"
            v-model.number="myVote.vocals"
            @change="submitVote"
          />
        </div>
  
        <div class="notes-section">
          <label>Notes:</label>
          <textarea v-model="myNote.content" @blur="submitNote" placeholder="Write your notes..."></textarea>
        </div>
  
        <div class="live-votes">
          <h3>Group Votes</h3>
          <ul>
            <li v-for="vote in groupVotes" :key="vote.user_id">
              <strong>{{ getUserName(vote.user_id) }}:</strong>
              Song: {{ vote.song }}, Performance: {{ vote.performance }}, Vocals: {{ vote.vocals }}
            </li>
          </ul>
        </div>
      </div>
    </main>
  </template>
  

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute} from 'vue-router'
import { supabase } from '../supabase'
import { watch } from 'vue'

const myVote = ref({ song: 0, performance: 0, vocals: 0 })
const myNote = ref({ content: '' })
const groupVotes = ref([])
const user = ref(null)
const country = ref({})
const groupId = ref(null) 
const route = useRoute()
const countryId = ref(parseInt(route.params.countryId))
const allCountries = ref([])
const prevCountryId = ref(null)
const nextCountryId = ref(null)

function getFlagUrl(filename) {
  return new URL(`../assets/flags/${filename}`, import.meta.url).href
}

function updateNavigationIds() {
  const index = allCountries.value.findIndex(c => c.id === countryId.value)
  if (index !== -1) {
    prevCountryId.value = allCountries.value[index - 1]?.id || null
    nextCountryId.value = allCountries.value[index + 1]?.id || null
  }
}

async function loadInitialData() {
  const { data: authData } = await supabase.auth.getUser()
  if (!authData?.user) return
  user.value = authData.user

  // Get profile
  const { data: profile } = await supabase
    .from('users')
    .select('group_id, name')
    .eq('id', user.value.id)
    .single()

  if (profile) groupId.value = profile.group_id

  // ✅ Load all countries (sorted)
  const { data: countries } = await supabase
    .from('countries')
    .select('id')
    .order('running_order')

  if (countries) {
    allCountries.value = countries
    updateNavigationIds()
  }

  // Get country
  const { data: countryData } = await supabase
    .from('countries')
    .select('*')
    .eq('id', countryId.value)
    .single()

  if (countryData) country.value = countryData

  // Get user's vote
  const { data: voteData } = await supabase
    .from('votes')
    .select('*')
    .eq('user_id', user.value.id)
    .eq('country_id', countryId.value)
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

  // Get group votes
  const { data: groupData } = await supabase
    .from('votes')
    .select('*')
    .eq('country_id', countryId.value)
    .eq('group_id', groupId.value)
  if (groupData) groupVotes.value = groupData
}

async function submitVote() {
    console.log("submit vote")
  await supabase.from('votes').upsert({
    user_id: user.value.id,
    group_id: groupId.value,
    country_id: countryId.value,
    ...myVote.value,
    updated_at: new Date().toISOString()
  })
}

async function submitNote() {
  await supabase.from('notes').upsert({
    user_id: user.value.id,
    group_id: groupId.value,
    country_id: countryId.value,
    content: myNote.value.content,
    updated_at: new Date().toISOString()
  })
}

function getUserName(userId) {
  return userId === user.value.id ? 'You' : userId
}

// Watch for route change (i.e. when clicking next/previous)
watch(() => route.params.countryId, async (newId, oldId) => {
  if (newId !== oldId) {
    myVote.value = { song: 0, performance: 0, vocals: 0 }
    myNote.value = { content: '' }
    groupVotes.value = []
    countryId.value = parseInt(newId)
    await loadInitialData()
    updateNavigationIds()
  }
})

onMounted(() => {
  loadInitialData()

  supabase.channel('votes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'votes' }, payload => {
      const newVote = payload.new
      if (newVote.country_id === countryId.value && newVote.group_id === groupId.value) {
        const idx = groupVotes.value.findIndex(v => v.user_id === newVote.user_id)
        if (idx >= 0) groupVotes.value[idx] = newVote
        else groupVotes.value.push(newVote)
      }
    })
    .subscribe()
})
</script>

  
<style scoped>

img{
    height: 100px;
}

.title{
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

input[type="range"] {
    width: 100%;
}

.country-voting {
    max-width: 600px;
    margin: auto;
    padding: 1em;
  }
  
  .voting-section label,
  .notes-section label {
    display: block;
    margin-top: 1em;
    font-weight: bold;
  }
  
  .voting-section select {
    width: 100px;
    font-size: 1rem;
    margin-top: 0.25em;
  }
  
  .notes-section textarea {
    width: 100%;
    min-height: 100px;
    margin-top: 0.25em;
    padding: 0.5em;
    font-size: 1rem;
    resize: vertical;
  }
  
  .live-votes {
    margin-top: 2em;
    /* background: #f4f4f4; */
    border-radius: 8px;
    padding: 1em;
    max-height: 200px;
    overflow-y: auto;
  }
  
  .live-votes ul {
    list-style: none;
    padding: 0;
    margin: 0;
  }
  
  .live-votes li {
    padding: 0.25em 0;
    border-bottom: 1px solid #ccc;
    font-size: 0.9rem;
  }

  .nav-buttons {
  display: flex;
  justify-content: space-between;
  max-width: 600px;
  margin: 1em auto;
  padding: 0 1em;
}

.nav-buttons button {
  background-color: #007bff;
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
  