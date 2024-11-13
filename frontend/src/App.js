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
  const { addressMO, connected } = useAppContext()
  const [showDepositBar, setShowDepositBar] = useState(false)

  useEffect(() => {
    if (connected) {
      setShowDepositBar(true)
    } else {
      setTimeout(() => setShowDepositBar(false), 300) 
    }
  }, [connected])

  return (
    <NotificationProvider>
      <NotificationList />
      <Router>
        <div className="app-root fade-in">
          <Header />
          {/**<nav>
            <Link to="/" onClick={() => setCurrentPage('home')}>Bridge</Link>
            <Link to="/Mint" onClick={() => setCurrentPage('mint')}>Insure</Link>
          </nav>**/}
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
