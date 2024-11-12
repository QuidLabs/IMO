import React from 'react'

import { useCallback, useEffect, useState } from "react"
import { Swiper, SwiperSlide } from "swiper/react"
import { EffectFlip, Navigation } from 'swiper/modules'

import { useAppContext } from "../contexts/AppContext"

import 'swiper/css'
import 'swiper/css/effect-flip'
import 'swiper/css/navigation'

import "../components/Adds/Styles/Slider.scss"

import '../pages/MainPage/MaintPage.scss'
import './Styles/VoteButton.scss'

export const VoteButton = ({ minValue, maxValue }) => {
  const { setStorage, account, mo } = useAppContext()

  const [rangeValues, setRangeValue] = useState('')

  const giveRange = useCallback((minValue, maxValue) => {
    let array = []

    for (let i = 0; i <= maxValue - minValue; i++) {
      array[i] = `${minValue + i}.0%`
    }

    return array
  }, [])

  const setNotifications = useCallback((severity, message, status = false) => {
    setStorage(prevNotifications => [
      ...prevNotifications,
      { severity: severity, message: message, status: status }
    ])
  }, [setStorage])

  const voteStarting = async (button) => {
    try {
        
        //setIsProcessing(true)
        setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
        //setInputValue("")

        if (account) {
          await mo.methods.FEE().call()

          setNotifications("success", "Your vote has been counted!", true)
        } else {

        }
    } catch (err) {
      const er = "MO::mint: supply cap exceeded"
      const msg = err.error?.message === er || err.message === er ? "Please wait for more QD to become mintable..." : err.error?.message || err.message

      setNotifications("error", msg)
    } finally {
      //setIsProcessing(false)
      //setInputValue("")
    }
  }

  useEffect(() => {
    setRangeValue(giveRange(minValue, maxValue))
  }, [giveRange, minValue, maxValue])

  return (
    <React.Fragment>
      <div className="vote-contaier">
        <Swiper
          effect={'flip'}
          grabCursor={true}
          navigation={true}
          modules={[EffectFlip, Navigation]}
          className="mySwiper"
          slidesPerView={1}
        //initialSlide={}
        //onSwiper={(swiper) => {}}
        //onSlideChange={}
        >
          {rangeValues ? rangeValues.map((value, key) => (
            <SwiperSlide key={"choise-value-" + key} name={value}>
              <div className="button-overflow">
                <button
                  //ref={buttonRef}
                  type="submit"
                  className={"mint-submit"}
                  name={value}
                  onClick={() => {voteStarting()}}
                >
                  {value}
                </button>
              </div>
            </SwiperSlide>
          )) : null}
        </Swiper>
      </div>
    </React.Fragment>
  )
}

export default VoteButton
