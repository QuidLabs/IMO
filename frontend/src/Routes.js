import React from 'react'
import { Routes, Route } from 'react-router-dom'
import HomePage from './pages/MainPage/HomePage'
import MaintPage from './pages/MainPage/MaintPage'

export const useRoutes = () => (
    <Routes>
      <Route path="/" element={<HomePage minValue={1} maxValue={9}/>} />
      <Route path="/Mint" element={<MaintPage />} />
    </Routes>
  )