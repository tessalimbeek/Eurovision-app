<script setup>
import { ref, onMounted } from 'vue'
import CountryBox from '@/components/CountryBox.vue'
import { supabase } from '../supabase'

const countries = ref([])

onMounted(async () => {
  const { data, error } = await supabase.from('countries').select('*').order('running_order')
  if (!error) countries.value = data
})
</script>

<template>
  <main>
    <h1>Eurovision Countries</h1>
    <div class="country-list">
      <CountryBox
        v-for="country in countries"
        :key="country.id"
        :country="country"
      />
    </div>
  </main>
</template>


<style scoped>
.country-list {
  display: flex;
  flex-direction: column;
  flex-wrap: wrap;
  gap: 1rem;
  justify-content: center;
  padding: 1rem;
}
</style>
