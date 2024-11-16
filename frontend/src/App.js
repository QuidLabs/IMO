import { BrowserRouter as Router } from 'react-router-dom'
import { useEffect, useState } from 'react'

import { NotificationList } from './components/NotificationList'
import { Footer } from './components/Footer'
import { Header } from './components/Header'
import { DepositBar } from './components/DepositBar'

import { NotificationProvider } from './contexts/NotificationProvider'
import { useRoutes } from './Routes'
import { useAppContext } from "./contexts/AppContext"

import './App.scss'

function App() {
  const routes = useRoutes()
  const { addressMO, connected, account } = useAppContext()
  const [showDepositBar, setShowDepositBar] = useState(false)
  const [initialRender, setInitialRender] = useState(true)

  useEffect(() => {
    if (initialRender) {
      setInitialRender(false) 
      return
    }

    if (account && connected) {
      setShowDepositBar(true)
    } else {
      const timer = setTimeout(() => setShowDepositBar(false), 300)
      return () => clearTimeout(timer) 
    }
  }, [account, connected, initialRender])

  return (
    <NotificationProvider>
      <NotificationList />
      <Router>
        <div className="app-root fade-in">
          <Header />
          <main className="app-main">
            <div className="app-container">
              {routes}
            </div>
          </main>
          {showDepositBar && addressMO && <DepositBar address={addressMO} />}
          <Footer />
        </div>
      </Router>
    </NotificationProvider>
  )
}

export default App
