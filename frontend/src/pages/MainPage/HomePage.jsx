import React from 'react'

import { useCallback, useEffect, useState } from "react"
import { Swiper, SwiperSlide } from "swiper/react"
import { EffectFlip, Navigation } from 'swiper/modules'

import { DepositBar } from "../../components/DepositBar"

import 'swiper/css'
import 'swiper/css/effect-flip'
import 'swiper/css/navigation'

import "../../components/Adds/Styles/Slider.scss"

import './MaintPage.scss'
import './HomePage.scss'

const HomePage = ({ minValue, maxValue }) => {
  const [rangeValues, setRangeValue] = useState('')

  const giveRange = useCallback((minValue, maxValue) => {
    let array = []

    for (let i = 0; i <= maxValue - minValue; i++) {
      array[i] = `${minValue + i}.0%`
    }

    return array
  }, [])

  useEffect(() => {
    setRangeValue(giveRange(minValue, maxValue))
  }, [giveRange, minValue, maxValue])

  return (
    <React.Fragment>
      <div className="main-side">
        <Swiper
          className="mySwiper"
          slidesPerView={1}
          initialSlide={0}
          //onSwiper={(swiper) => {}}
        >
          <SwiperSlide>
            <DepositBar />
          </SwiperSlide>
        </Swiper>
      </div>
      <div className="buttons-anim main-content">
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
                //onClick={(e) => {}}
                >
                  {value}
                  <div className={`mint-glowEffect mint-glow-on`}>
                    <div className={`mint-submit-hide`}>
                      {value}
                    </div>
                  </div>
                </button>
              </div>
            </SwiperSlide>
          )) : null}
        </Swiper>
      </div>
      <div className="main-fakeCol" />
    </React.Fragment>
  )
}

export default HomePage
