import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import api from '../utils/api';
import { ArrowLeft, Play, Pause, Volume2, Maximize, Settings, RotateCcw, RotateCw, Monitor, Subtitles, Zap, Info, AlertTriangle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Player = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const season = queryParams.get('s');
  const episode = queryParams.get('e');

  const [movie, setMovie] = useState(null);
  const [sources, setSources] = useState([]);
  const [subtitles, setSubtitles] = useState([]);
  const [selectedSource, setSelectedSource] = useState(null);
  const [sourceIndex, setSourceIndex] = useState(0);
  const [selectedSubtitle, setSelectedSubtitle] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [showControls, setShowControls] = useState(true);
  const [showSourceSelector, setShowSourceSelector] = useState(false);
  const [showSubtitleSelector, setShowSubtitleSelector] = useState(false);
  const [isError, setIsError] = useState(false);
  const videoRef = useRef(null);
  const controlsTimerRef = useRef(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const movieRes = await api.get(`/movies/${id}`);
        setMovie(movieRes.data);

        let sourcesUrl = `/api/v1/movie/${id}/sources`;
        if (season && episode) {
          sourcesUrl = `/api/v1/tv/${id}/sources/${season}/${episode}`;
        }
        const response = await api.get(sourcesUrl);
        const sourcesData = response.data.sources || [];
        const subtitlesData = response.data.subtitles || [];

        setSources(sourcesData);
        setSubtitles(subtitlesData);

        if (sourcesData.length > 0) {
          setSelectedSource(sourcesData[0]);
          setSourceIndex(0);
        }
      } catch (err) {
        console.error(err);
        setIsError(true);
      }
    };
    fetchData();
  }, [id, season, episode]);

  const handleMouseMove = () => {
    setShowControls(true);
    if (controlsTimerRef.current) clearTimeout(controlsTimerRef.current);
    controlsTimerRef.current = setTimeout(() => {
      if (isPlaying) setShowControls(false);
    }, 4000);
  };

  const togglePlay = () => {
    if (!videoRef.current) return;
    if (videoRef.current.paused) {
      videoRef.current.play();
      setIsPlaying(true);
    } else {
      videoRef.current.pause();
      setIsPlaying(false);
    }
  };

  const handleVideoError = () => {
    console.warn(`Source ${sourceIndex} failed: ${selectedSource?.label}. Trying next...`);
    if (sourceIndex + 1 < sources.length) {
      const nextIndex = sourceIndex + 1;
      setSourceIndex(nextIndex);
      setSelectedSource(sources[nextIndex]);
      setIsError(false);
    } else {
      setIsError(true);
    }
  };

  const onTimeUpdate = () => {
    if (videoRef.current) {
      setProgress((videoRef.current.currentTime / videoRef.current.duration) * 100);
    }
  };

  const onLoadedMetadata = () => {
    if (videoRef.current) {
      setDuration(videoRef.current.duration);
    }
  };

  const handleSeek = (e) => {
    if (!videoRef.current) return;
    const seekTime = (e.target.value / 100) * videoRef.current.duration;
    videoRef.current.currentTime = seekTime;
    setProgress(e.target.value);
  };

  const formatTime = (time) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
  };

  if (isError) return (
      <div className="h-screen bg-[#050505] flex flex-col items-center justify-center space-y-6">
          <AlertTriangle size={64} className="text-red-600 animate-bounce" />
          <div className="text-white font-black uppercase italic tracking-widest text-2xl text-center">
              All Stream Links Failed<br/>
              <span className="text-slate-500 text-sm font-bold uppercase mt-4 block">Please try again later or contact support.</span>
          </div>
          <button onClick={() => navigate(-1)} className="bg-purple-600 px-8 py-3 rounded-xl font-black uppercase tracking-widest text-xs">Return Home</button>
      </div>
  );

  if (!movie) return (
    <div className="h-screen bg-[#050505] flex flex-col items-center justify-center space-y-8">
        <motion.div
            animate={{ rotate: 360, scale: [1, 1.2, 1] }}
            transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }}
            className="w-16 h-16 border-t-4 border-purple-600 border-solid rounded-full shadow-[0_0_50px_rgba(139,92,246,0.2)]"
        />
        <div className="text-white font-black uppercase tracking-[0.4em] text-[10px] animate-pulse">Initializing Theatre Mode</div>
    </div>
  );

  const isEmbed = selectedSource?.type === 'embed';

  return (
    <div
      className="fixed inset-0 z-[100] bg-black group overflow-hidden select-none cursor-none"
      onMouseMove={handleMouseMove}
    >
      <AnimatePresence>
        {showControls && (
            <motion.div
                initial={{ opacity: 0, y: -40 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -40 }}
                className="absolute top-0 left-0 w-full p-10 z-[110] flex items-center justify-between pointer-events-none"
            >
                <button
                    onClick={() => navigate(-1)}
                    className="pointer-events-auto flex items-center space-x-6 text-white group"
                >
                    <div className="bg-white/5 p-5 rounded-[1.2rem] border border-white/10 group-hover:bg-purple-600 transition-all shadow-2xl">
                        <ArrowLeft size={24} />
                    </div>
                    <div className="flex flex-col">
                        <span className="text-[9px] font-black uppercase tracking-[0.5em] text-purple-500 mb-1">Exit Playback</span>
                        <span className="text-3xl font-black uppercase italic tracking-tighter leading-none group-hover:text-purple-500 transition-colors">{movie.title} {season && ` • S${season}E${episode}`}</span>
                    </div>
                </button>

                <div className="pointer-events-auto glass px-6 py-3 rounded-2xl flex items-center space-x-4 border border-white/10">
                    <Zap size={18} className="text-purple-500 fill-purple-500" />
                    <span className="text-[10px] font-black uppercase tracking-widest text-slate-400">Stream: {selectedSource?.label || 'Secure Server'}</span>
                </div>
            </motion.div>
        )}
      </AnimatePresence>

      {/* Primary Video Container */}
      <div className="w-full h-full bg-[#000]">
        {isEmbed ? (
          <iframe
            src={selectedSource?.url}
            className="w-full h-full border-none pointer-events-auto"
            allowFullScreen
            title="Video Player"
          />
        ) : (
          <video
            ref={videoRef}
            src={selectedSource?.url || movie.videoUrl}
            className="w-full h-full object-contain pointer-events-auto"
            onTimeUpdate={onTimeUpdate}
            onLoadedMetadata={onLoadedMetadata}
            onError={handleVideoError}
            onClick={togglePlay}
            autoPlay
          >
            {selectedSubtitle && (
              <track
                label={selectedSubtitle.language}
                kind="subtitles"
                srcLang="en"
                src={selectedSubtitle.url}
                default
              />
            )}
          </video>
        )}
      </div>

      {/* Premium UI Overlay */}
      {!isEmbed && (
        <AnimatePresence>
            {showControls && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-black/40 flex flex-col justify-end p-10 md:p-16"
                >
                    {/* Cinematic Seek Bar */}
                    <div className="w-full mb-12 group/seek pointer-events-auto">
                        <div className="relative w-full h-1 bg-white/10 rounded-full overflow-hidden">
                            <div
                                className="absolute left-0 top-0 h-full bg-purple-600 shadow-[0_0_20px_rgba(139,92,246,0.8)]"
                                style={{ width: `${progress}%` }}
                            />
                        </div>
                        <input
                            type="range"
                            min="0"
                            max="100"
                            value={progress}
                            onChange={handleSeek}
                            className="absolute -top-1 left-0 w-full opacity-0 cursor-pointer h-3"
                        />
                        <div className="flex justify-between text-[11px] mt-6 font-black font-mono text-slate-500 tracking-[0.3em] uppercase">
                            <span className="text-purple-500">{formatTime(videoRef.current?.currentTime || 0)}</span>
                            <span>{formatTime(duration)}</span>
                        </div>
                    </div>

                    {/* Master Controls */}
                    <div className="flex items-center justify-between pointer-events-auto">
                        <div className="flex items-center space-x-16">
                            <button onClick={togglePlay} className="text-white hover:scale-110 active:scale-90 transition-all">
                                {isPlaying ? <Pause size={72} fill="white" /> : <Play size={72} fill="white" className="ml-2" />}
                            </button>

                            <div className="flex items-center space-x-8">
                                <button onClick={() => videoRef.current.currentTime -= 10} className="text-slate-400 hover:text-white transition-all">
                                    <RotateCcw size={36} />
                                </button>
                                <button onClick={() => videoRef.current.currentTime += 10} className="text-slate-400 hover:text-white transition-all">
                                    <RotateCw size={36} />
                                </button>
                            </div>

                            <div className="flex items-center space-x-6 group/vol bg-white/5 px-6 py-4 rounded-3xl border border-white/5">
                                <Volume2 size={24} className="text-slate-400 group-hover/vol:text-white transition-colors" />
                                <input type="range" className="w-24 accent-white h-1 appearance-none bg-white/10 rounded-full" />
                            </div>
                        </div>

                        <div className="flex items-center space-x-10">
                            <button
                                onClick={() => setShowSubtitleSelector(true)}
                                className={`flex flex-col items-center space-y-2 transition-all ${selectedSubtitle ? 'text-purple-500 scale-110' : 'text-slate-500 hover:text-white'}`}
                            >
                                <Subtitles size={32} />
                                <span className="text-[10px] font-black uppercase tracking-[0.2em]">{selectedSubtitle?.language || 'Off'}</span>
                            </button>

                            <button
                                onClick={() => setShowSourceSelector(true)}
                                className="flex items-center space-x-5 glass-dark px-8 py-4 rounded-[1.5rem] border border-white/10 hover:border-purple-600 transition-all text-white group"
                            >
                                <Monitor size={24} className="text-purple-500" />
                                <div className="flex flex-col items-start leading-none">
                                    <span className="text-[9px] font-black uppercase tracking-[0.3em] text-slate-500 mb-1">Mirror</span>
                                    <span className="text-sm font-black uppercase tracking-widest">{selectedSource?.label || 'Direct'}</span>
                                </div>
                            </button>

                            <button
                                onClick={() => videoRef.current.requestFullscreen()}
                                className="text-slate-500 hover:text-white hover:scale-110 transition-transform"
                            >
                                <Maximize size={32} />
                            </button>
                        </div>
                    </div>
                </motion.div>
            )}
        </AnimatePresence>
      )}

      {/* Floating Server UI (Embed Mode) */}
      {isEmbed && showControls && (
          <div className="absolute bottom-16 right-16 z-[120] pointer-events-auto">
             <motion.button
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                onClick={() => setShowSourceSelector(true)}
                className="bg-purple-600 text-white px-10 py-5 rounded-[1.8rem] font-black uppercase tracking-[0.3em] text-[11px] flex items-center space-x-5 hover:bg-purple-700 transition-all shadow-[0_30px_100px_rgba(139,92,246,0.5)] active:scale-95 border-b-4 border-black/20"
              >
                <Monitor size={22} />
                <span>Switch Mirror</span>
              </motion.button>
          </div>
      )}

      {/* Full-Screen Selection Overlays */}
      <AnimatePresence>
        {(showSourceSelector || showSubtitleSelector) && (
            <SelectionModal
                title={showSourceSelector ? "Select Mirror" : "Subtitles"}
                items={showSourceSelector ? sources : [{language: 'Off'}, ...subtitles]}
                selectedItem={showSourceSelector ? selectedSource : (selectedSubtitle || {language: 'Off'})}
                onSelect={(item, index) => {
                    if (showSourceSelector) {
                        setSelectedSource(item);
                        setSourceIndex(index);
                        setShowSourceSelector(false);
                        setIsError(false);
                    } else {
                        setSelectedSubtitle(item.language === 'Off' ? null : item);
                        setShowSubtitleSelector(false);
                    }
                }}
                onClose={() => {
                    setShowSourceSelector(false);
                    setShowSubtitleSelector(false);
                }}
                renderItem={(item) => (
                    <div className="flex items-center justify-between w-full">
                        <div className="text-left">
                            <div className="text-white font-black text-3xl uppercase italic tracking-tighter mb-1">{item.label || item.language}</div>
                            <div className="text-slate-500 text-[10px] font-black uppercase tracking-[0.4em]">{item.quality || 'Auto'} • {item.provider || 'Secure'}</div>
                        </div>
                        <div className="w-12 h-12 rounded-full border border-white/10 flex items-center justify-center">
                            <Zap size={20} className="text-purple-500" />
                        </div>
                    </div>
                )}
            />
        )}
      </AnimatePresence>
    </div>
  );
};

const SelectionModal = ({ title, items, selectedItem, onSelect, onClose, renderItem }) => (
    <motion.div
        initial={{ opacity: 0, scale: 1.1 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 1.1 }}
        className="absolute inset-0 bg-[#050505]/98 z-[300] flex items-center justify-center p-12 backdrop-blur-3xl pointer-events-auto"
    >
        <div className="max-w-5xl w-full">
            <div className="flex items-end justify-between mb-20">
                <div>
                    <h2 className="text-8xl font-black text-white italic uppercase tracking-tighter leading-none mb-4">{title}</h2>
                    <div className="h-2 w-32 bg-purple-600"></div>
                </div>
                <button onClick={onClose} className="p-6 bg-white/5 rounded-full hover:bg-white/10 transition-all text-slate-500 hover:text-white">
                    <Maximize size={40} className="rotate-45" />
                </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-h-[50vh] overflow-y-auto pr-8 custom-scrollbar">
                {items.map((item, index) => (
                    <button
                        key={index}
                        onClick={() => onSelect(item, index)}
                        className={`p-10 rounded-[2.5rem] transition-all transform hover:scale-[1.03] active:scale-95 ${
                            (selectedItem?.label === item.label || selectedItem?.language === item.language)
                            ? 'bg-purple-600 shadow-[0_0_80px_rgba(139,92,246,0.4)] border-transparent'
                            : 'bg-white/5 border border-white/5 hover:border-purple-600/50 hover:bg-white/10'
                        }`}
                    >
                        {renderItem(item)}
                    </button>
                ))}
            </div>
        </div>
    </motion.div>
);

export default Player;
