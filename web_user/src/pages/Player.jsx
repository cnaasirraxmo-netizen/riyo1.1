import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import api from '../utils/api';
import { ArrowLeft, Play, Pause, Volume2, Maximize, Settings, RotateCcw, RotateCw, Monitor, Subtitles, Zap } from 'lucide-react';
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
  const [selectedSubtitle, setSelectedSubtitle] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [showControls, setShowControls] = useState(true);
  const [showSourceSelector, setShowSourceSelector] = useState(false);
  const [showSubtitleSelector, setShowSubtitleSelector] = useState(false);
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
        }
      } catch (err) {
        console.error(err);
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

  if (!movie) return (
    <div className="h-screen bg-[#0a0a0a] flex flex-col items-center justify-center space-y-6">
        <motion.div
            animate={{ rotate: 360 }}
            transition={{ repeat: Infinity, duration: 1, ease: "linear" }}
            className="w-12 h-12 border-t-2 border-purple-600 border-solid rounded-full"
        />
        <div className="text-purple-500 font-black uppercase italic tracking-widest animate-pulse">Establishing Connection...</div>
    </div>
  );

  const isEmbed = selectedSource?.type === 'embed';

  return (
    <div
      className="fixed inset-0 z-[100] bg-black group overflow-hidden select-none"
      onMouseMove={handleMouseMove}
    >
      <AnimatePresence>
        {showControls && (
            <motion.div
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                className="absolute top-0 left-0 w-full p-8 z-[110] flex items-center justify-between pointer-events-none"
            >
                <button
                    onClick={() => navigate(-1)}
                    className="pointer-events-auto flex items-center space-x-4 text-white hover:text-purple-400 transition-all group"
                >
                    <div className="bg-white/5 p-4 rounded-2xl border border-white/10 group-hover:bg-purple-600/20 group-hover:border-purple-600/50">
                        <ArrowLeft size={24} />
                    </div>
                    <div className="flex flex-col">
                        <span className="text-[10px] font-black uppercase tracking-[0.3em] text-gray-500">Back to Library</span>
                        <span className="text-xl font-black uppercase italic tracking-tighter">{movie.title} {season && ` • S${season}E${episode}`}</span>
                    </div>
                </button>

                <div className="pointer-events-auto bg-purple-600/10 border border-purple-500/20 px-4 py-2 rounded-xl flex items-center space-x-3">
                    <Zap size={16} className="text-purple-500 fill-purple-500" />
                    <span className="text-[10px] font-black uppercase tracking-widest text-purple-500">Streaming via {selectedSource?.provider || 'Direct'}</span>
                </div>
            </motion.div>
        )}
      </AnimatePresence>

      {/* Video Content */}
      <div className="w-full h-full bg-black">
        {isEmbed ? (
          <iframe
            src={selectedSource.url}
            className="w-full h-full border-none shadow-[0_0_100px_rgba(147,51,234,0.1)]"
            allowFullScreen
            title="Video Player"
          />
        ) : (
          <video
            ref={videoRef}
            src={selectedSource?.url || movie.videoUrl}
            className="w-full h-full cursor-none object-contain"
            onTimeUpdate={onTimeUpdate}
            onLoadedMetadata={onLoadedMetadata}
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

      {/* Controls Overlay (Only for non-embed) */}
      {!isEmbed && (
        <AnimatePresence>
            {showControls && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-black/40 flex flex-col justify-end p-8 md:p-12"
                >
                    {/* Progress Bar */}
                    <div className="w-full mb-10 group/seek">
                        <input
                        type="range"
                        min="0"
                        max="100"
                        value={progress}
                        onChange={handleSeek}
                        className="w-full h-1 bg-white/10 rounded-full appearance-none cursor-pointer accent-purple-600 hover:h-2.5 transition-all"
                        />
                        <div className="flex justify-between text-xs mt-4 font-black font-mono text-white/50 tracking-[0.2em]">
                        <span>{formatTime(videoRef.current?.currentTime || 0)}</span>
                        <span>{formatTime(duration)}</span>
                        </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-12">
                        <button onClick={togglePlay} className="text-white hover:scale-125 transition-transform">
                            {isPlaying ? <Pause size={56} fill="white" /> : <Play size={56} fill="white" className="ml-1" />}
                        </button>
                        <div className="flex items-center space-x-6">
                            <button onClick={() => videoRef.current.currentTime -= 10} className="text-white/60 hover:text-white transition-all">
                            <RotateCcw size={32} />
                            </button>
                            <button onClick={() => videoRef.current.currentTime += 10} className="text-white/60 hover:text-white transition-all">
                            <RotateCw size={32} />
                            </button>
                        </div>
                        <div className="flex items-center space-x-4 group/vol">
                            <Volume2 size={24} className="text-white/60" />
                            <input type="range" className="w-0 group-hover/vol:w-24 transition-all accent-purple-600 h-1 appearance-none bg-white/10 rounded-full" />
                        </div>
                        </div>

                        <div className="flex items-center space-x-8">
                        <button
                            onClick={() => setShowSubtitleSelector(true)}
                            className={`flex flex-col items-center space-y-1 transition-all ${selectedSubtitle ? 'text-purple-400 scale-110' : 'text-white/40 hover:text-white'}`}
                        >
                            <Subtitles size={28} />
                            <span className="text-[8px] font-black uppercase tracking-widest">{selectedSubtitle?.language || 'Off'}</span>
                        </button>

                        <button
                            onClick={() => setShowSourceSelector(true)}
                            className="flex items-center space-x-3 bg-white/5 px-6 py-3 rounded-2xl border border-white/10 hover:border-purple-500/50 hover:bg-purple-600/10 transition-all text-white/80"
                        >
                            <Monitor size={20} />
                            <div className="flex flex-col items-start">
                                <span className="text-[8px] font-black uppercase tracking-widest text-gray-500">Source Server</span>
                                <span className="text-xs font-black uppercase tracking-widest">{selectedSource?.label || 'Select'}</span>
                            </div>
                        </button>

                        <button
                            onClick={() => videoRef.current.requestFullscreen()}
                            className="text-white/40 hover:text-white hover:scale-110 transition-transform"
                        >
                            <Maximize size={28} />
                        </button>
                        </div>
                    </div>
                </motion.div>
            )}
        </AnimatePresence>
      )}

      {/* Floating Source Selector (For embed mode) */}
      {isEmbed && showControls && (
          <div className="absolute bottom-12 right-12 z-[120]">
             <motion.button
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                onClick={() => setShowSourceSelector(true)}
                className="bg-purple-600 text-white px-8 py-4 rounded-2xl font-black uppercase tracking-[0.2em] text-xs flex items-center space-x-4 hover:bg-purple-700 transition-all shadow-[0_20px_50px_rgba(147,51,234,0.4)] active:scale-95"
              >
                <Monitor size={20} />
                <span>Change Server</span>
              </motion.button>
          </div>
      )}

      {/* Modern Fullscreen Selection Overlays */}
      <AnimatePresence>
        {showSourceSelector && (
            <SelectionOverlay
                title="Select Server"
                subtitle="Choose a high-speed streaming server for the best experience"
                items={sources}
                selectedItem={selectedSource}
                onSelect={(item) => {
                    setSelectedSource(item);
                    setShowSourceSelector(false);
                }}
                onClose={() => setShowSourceSelector(false)}
                renderItem={(source) => (
                    <>
                    <div className="text-white font-black text-2xl mb-1 italic uppercase tracking-tighter">{source.label}</div>
                    <div className="text-zinc-500 text-[10px] font-black uppercase tracking-[0.3em]">{source.quality} • {source.provider} • Cloud Layer</div>
                    </>
                )}
            />
        )}

        {showSubtitleSelector && (
            <SelectionOverlay
                title="Subtitles"
                subtitle="Select your preferred language for CC"
                items={[{language: 'Off'}, ...subtitles]}
                selectedItem={selectedSubtitle || {language: 'Off'}}
                onSelect={(item) => {
                    setSelectedSubtitle(item.language === 'Off' ? null : item);
                    setShowSubtitleSelector(false);
                }}
                onClose={() => setShowSubtitleSelector(false)}
                renderItem={(sub) => (
                    <div className="text-white font-black text-2xl py-2 italic uppercase tracking-tighter">{sub.language}</div>
                )}
            />
        )}
      </AnimatePresence>
    </div>
  );
};

const SelectionOverlay = ({ title, subtitle, items, selectedItem, onSelect, onClose, renderItem }) => (
  <motion.div
    initial={{ opacity: 0 }}
    animate={{ opacity: 1 }}
    exit={{ opacity: 0 }}
    className="absolute inset-0 bg-[#0a0a0a]/95 z-[200] flex items-center justify-center p-8 backdrop-blur-2xl"
  >
    <div className="max-w-4xl w-full">
      <div className="flex flex-col space-y-2 mb-16 border-l-8 border-purple-600 pl-8">
        <h2 className="text-6xl font-black text-white italic uppercase tracking-tighter leading-none">{title}</h2>
        <p className="text-gray-500 font-bold uppercase tracking-widest text-xs">{subtitle}</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-h-[50vh] overflow-y-auto pr-6 custom-scrollbar">
        {items.map((item, index) => (
          <button
            key={index}
            onClick={() => onSelect(item)}
            className={`group p-8 rounded-[2rem] text-left transition-all transform hover:scale-[1.02] ${
              (selectedItem?.label === item.label || selectedItem?.language === item.language)
              ? 'bg-purple-600 shadow-[0_25px_60px_rgba(147,51,234,0.3)]'
              : 'bg-white/5 border border-white/5 hover:border-purple-500/30 hover:bg-white/10'
            }`}
          >
            {renderItem(item)}
          </button>
        ))}
      </div>

      <div className="mt-16 flex justify-center">
        <button
            onClick={onClose}
            className="group flex flex-col items-center space-y-4"
        >
            <div className="w-16 h-16 rounded-full border-2 border-white/10 flex items-center justify-center group-hover:border-purple-600 group-hover:bg-purple-600 transition-all">
                <Maximize size={24} className="rotate-45 text-white" />
            </div>
            <span className="text-[10px] font-black uppercase tracking-[0.5em] text-gray-600 group-hover:text-white transition-colors">Dismiss</span>
        </button>
      </div>
    </div>
  </motion.div>
);

export default Player;
