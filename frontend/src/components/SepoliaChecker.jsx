import { useEffect, useCallback, useRef } from 'react'
import { useAppContext } from "../contexts/AppContext"

export const SepoliaChecker = () => {
  const { setStorage } = useAppContext()
  const hasCheckedRef = useRef(false)  

  const setNotifications = useCallback((severity, message, status = false) => {
    setStorage(prevNotifications => [
      ...prevNotifications,
      { severity: severity, message: message, status: status }
    ])
  }, [setStorage])

  useEffect(() => {
    const checkAndSwitchChain = async () => {
      if (hasCheckedRef.current) return
      hasCheckedRef.current = true

      if (window.ethereum) {
        try {
          const currentChainId = await window.ethereum.request({ method: 'eth_chainId' })

          if (currentChainId.toLowerCase() === '0xaa36a7') {
            return
          }

          setNotifications('info', 'Requesting to switch to Sepolia Testnet...')
          await new Promise(resolve => setTimeout(resolve, 500)) 

          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0xaa36a7' }],
          })

          const newChainId = await window.ethereum.request({ method: 'eth_chainId' })
          if (newChainId.toLowerCase() === '0xaa36a7') {
            setNotifications('success', 'Successfully switched to Sepolia Testnet')
          } else {
            setNotifications('error', 'Failed to switch to Sepolia Testnet')
          }
        } catch (error) {
          if (error.code === 4902) {
            setNotifications('error', 'Sepolia network not found in wallet. Please add it manually.')
          } else if (error.code === 4001) {
            setNotifications('info', 'Network switch request was rejected by the user.')
          } else {
            setNotifications('error', `Error: ${error.message}`)
          }
          console.error('Error during chain check or switch:', error)
        }
      } else {
        setNotifications('error', 'Ethereum provider not detected. Please install MetaMask.')
      }
    }

    const onChainChanged = (chainId) => {
      if (chainId.toLowerCase() === '0xaa36a7') {
        setNotifications('success', 'Connected to Sepolia Testnet')
      } else {
        setNotifications('info', 'Requesting a switch to Sepolia Testnet...')
        checkAndSwitchChain()
      }
    }

    checkAndSwitchChain()

    if (window.ethereum) {
      window.ethereum.on('chainChanged', onChainChanged)
    }

    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('chainChanged', onChainChanged)
      }
    }
  }, [setNotifications])

  return null
}

export default SepoliaChecker
