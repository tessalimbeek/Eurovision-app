import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

import LoginView from '../views/LoginView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
    path: '/',
    component: LoginView,
    },
    {
    path: '/home',
    component: HomeView,
    },
    {
      path: '/chat',
      name: 'chat',
      component: () => import('../views/ChatView.vue'),
    },
    {
    path: '/scores',
    name: 'scores',
    component: () => import('../views/ScoresListView.vue'),
    },
    {
    path: '/profile',
    name: 'profile',
    component: () => import('../views/ProfileView.vue'),
    },
    // {
    // path: '/vote/:countryId',
    // name: 'VotingPage',
    // component: () => import('@/views/VotingPage.vue')
    // },
    {
        path: '/countries/:phase?',
        name: 'countries',
        component: () => import('../views/CountriesView.vue'),
        props: route => ({ 
          phase: route.params.phase || 'semi1' // default to semi1 if no phase
        })
      },
      // Single voting route with phase parameter
      {
        path: '/vote/:phase/:countryId',
        name: 'VotingPage',
        component: () => import('@/views/VotingPage.vue'),
        props: route => ({ 
          countryId: route.params.countryId, 
          phase: route.params.phase 
        })
      },        
  ],
})


export default router
