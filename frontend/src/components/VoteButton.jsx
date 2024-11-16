import React, { useCallback, useEffect, useRef, useState } from "react"
import { useAppContext } from "../contexts/AppContext"

import "./Styles/VoteButton.scss"

export const VoteButton = ({ minValue = 1, maxValue = 9 }) => {
  const { setStorage, account, quid } = useAppContext()

  const savedVote = localStorage.getItem("saveQUIDVote")
  const [rangeValue, setRangeValue] = useState(savedVote ? parseFloat(savedVote) : minValue)
  const animationFrameRef = useRef(null)
  const [animatedValue, setAnimatedValue] = useState(rangeValue)

  const setNotifications = useCallback(
    (severity, message, status = false) => {
      setStorage((prevNotifications) => [
        ...prevNotifications,
        { severity: severity, message: message, status: status }
      ])
    },
    [setStorage]
  )

  const voteStarting = async () => {
    try { 
      if(account){
        //const oldFeeVote = await mo.methods.FEE().call()
        const oldVote = localStorage.getItem("saveQUIDVote")

        if (rangeValue.toString() !== oldVote) {
          setNotifications(
            "info",
            "Processing. Please don't close or refresh page when terminal is working"
          )
          
          const calculateVote = rangeValue*10 - 2
          await quid.methods.vote(calculateVote).send({ from: account })
            .then(() => {
              localStorage.setItem("saveQUIDVote", JSON.stringify(rangeValue))
            })
  
          setNotifications("success", "Your vote has been counted!", true)
        } else setNotifications("error", "Your new voice should be different from your previous one.", true)
      }
    } catch (err) {
      const er = "MO::mint: supply cap exceeded";
      const msg =
        err.error?.message === er || err.message === er
          ? "Please wait for more QD to become mintable..."
          : err.error?.message || err.message
      setNotifications("error", msg)
    }
  }

  useEffect(() => {
    if (savedVote) {
      setRangeValue(parseFloat(savedVote))
    }
  }, [savedVote])

  const animateValue = (targetValue) => {
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current)
    }

    const step = () => {
      setAnimatedValue((prevValue) => {
        const diff = targetValue - prevValue
        const increment = diff * 0.1
        const newValue = prevValue + increment

        if (Math.abs(diff) < 0.1) {
          return targetValue
        }
        return newValue
      })

      animationFrameRef.current = requestAnimationFrame(step)
    }

    step()
  }

  useEffect(() => {
    animateValue(rangeValue)
  }, [rangeValue])

  const getMarkerPosition = () => {
    const percentage = (((animatedValue - minValue) / (maxValue - minValue)).toFixed(2)) * 100
    return `calc(${percentage}% - 25px)`
  }

  return (
    <div className="vote-container fade-in">
      <div className="custom-range-container">
        <input
          id="voteRange"
          type="range"
          min={minValue}
          max={maxValue}
          step={0.1}
          value={rangeValue}
          onChange={(e) => setRangeValue(parseFloat(e.target.value))}
          className="vote-range"
          onDoubleClick={() => voteStarting()}
          style={{
            backgroundSize: `${((rangeValue - minValue) / (maxValue - minValue)) * 100}% 100%`
          }}
        />
        <div
          className="custom-marker"
          style={{
            left: getMarkerPosition()
          }}
        >
          {animatedValue.toFixed(1)}%
        </div>
        <div className="custom-line"></div>
      </div>
    </div>
  )
}

export default VoteButton
