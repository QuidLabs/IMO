import { useCallback, useEffect, useState } from "react"

import { Swiper, SwiperSlide } from "swiper/react"
import { EffectFlip, Navigation } from 'swiper/modules'

import { useAppContext } from "../../contexts/AppContext"


import 'swiper/css'
import 'swiper/css/effect-flip'
import 'swiper/css/navigation'

import "./Styles/Slider.scss"

export function Buttons({ names, initialSlide, buttonRef, isProcessing, handleSubmit }) {
    const { choiseButton, account, connected, notifications, quid } = useAppContext()

    const [glowClass, setGlowClass] = useState('')

    const changeButton = useCallback((isProcessing, state) => {
        try {
            if (state) return (isProcessing ? 'off' : 'on')
            else return ('off')
        } catch (error) {
            console.error(error)
        }
    }, [])

    useEffect(() => {
        if (account && connected && quid) {
            const classState = changeButton(isProcessing, true)

            setGlowClass(classState)
        }
        if (notifications[0] && !connected) setTimeout(() => {
            const classState = changeButton(isProcessing, false)

            setGlowClass(classState)
        }, 500)
    }, [changeButton, isProcessing, account, connected, quid, notifications])

    return (
        <div className="buttons-anim" >
            <Swiper
                effect={'flip'}
                grabCursor={true}
                navigation={true}
                modules={[EffectFlip, Navigation]}
                className="mySwiper"
                slidesPerView={1}
                initialSlide={initialSlide}
                >
                {names.map((name, key) => (
                    <SwiperSlide key={"mint_button_" + key} >
                        <div className="button-overflow" >
                            <button
                                ref={buttonRef}
                                type="submit"
                                className={isProcessing ? "mint-processing" : "mint-submit"}
                                name={name}
                                onClick={(name) => {
                                    choiseButton(name.target.name)
                                    handleSubmit()
                                }}
                            >
                                {isProcessing ? "Processing" : name}
                                <div className={`mint-glowEffect mint-glow-${glowClass}`} />
                            </button>
                        </div>
                    </SwiperSlide>
                ))}
            </Swiper >
        </div>
    )
}