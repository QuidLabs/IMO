import cx from "classnames";
import { Icon } from "./Icon.jsx";
import { useEffect, useRef, useState } from "react";

import "./Styles/Footer.scss";

export const Footer = () => {
  const [isPlaying, setIsPlaying] = useState(false);
  const player = useRef();

  const togglePlay = () => {
    if (!player.current) return;
    if (isPlaying) {
      setIsPlaying(false);
      player.current.pause();
    } else {
      setIsPlaying(true);
      player.current.play();
    }
  };

  useEffect(() => {
    const play = () => {
      setIsPlaying(false);
      document.removeEventListener("mousedown", play);
      document.removeEventListener("keydown", play);
      document.removeEventListener("touchstart", play);
    };
    document.addEventListener("mousedown", play);
    document.addEventListener("keydown", play);
    document.addEventListener("touchstart", play);
  }, []);

  return (
    <footer className="footer-root">
      <div className="footer-media">
        <audio ref={(el) => (player.current = el)} autoPlay={false} loop>
          <source src="/sounds/song.mp3" type="audio/mpeg" />
        </audio>
        <button className="footer-music" onClick={togglePlay}>
          <Icon name="music-wave" className="footer-musicWave" />
          Music is {isPlaying ? 'on' : 'off'}
        </button>
        <div className="footer-spacer" />
        <a
          href="https://vimeo.com/1034967054"
          target="_blank"
          rel="noreferrer"
          className="footer-youtube"
        >
          <Icon name="youtube" className="footer-youtubeIcon" />
          Video
        </a>
      </div>

      <div className="footer-socialLinks">
        <a
          href="https://twitter.com/quidmint"
          className={cx('footer-socialLink', 'footer-socialLink2')}
        >
          <Icon name="twitter" className="footer-socialIcon" />
          <Icon name="link-hover-2" className="footer-socialIconHover" />
        </a>
        <a
          href="https://mirror.xyz/quid.eth"
          className={cx('footer-socialLink', 'footer-socialLink3')}
        >
          <Icon name="medium" className="footer-socialIcon" />
          <Icon name="link-hover-3" className="footer-socialIconHover" />
        </a>
        <a
          href="https://github.com/QuidMint/IMO/blob/main/README.md"
          target="_blank"
          rel="noreferrer"
          className={cx('footer-socialLink', 'footer-socialLink2')}
        >
          <Icon name="github" className="footer-socialIcon" />
          <Icon name="link-hover-2" className="footer-socialIconHover" />
        </a>
        <a
          href="mailto:john@quid.io"
          className={cx('footer-socialLink', 'footer-socialLink3')}
        >
          <Icon name="email" className="footer-socialIcon" />
          <Icon name="link-hover-3" className="footer-socialIconHover" />
        </a>
      </div>
    </footer>
  );
};
