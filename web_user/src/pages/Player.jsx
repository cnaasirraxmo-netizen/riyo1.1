import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import api from '../utils/api';
import { ArrowLeft, Play, Pause, Volume2, Maximize, Settings, RotateCcw, RotateCw, Monitor } from 'lucide-react';

const Player = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const season = queryParams.get('s');
  const episode = queryParams.get('e');

  const [movie, setMovie] = useState(null);
  const [sources, setSources] = useState([]);
  const [selectedSource, setSelectedSource] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [showControls, setShowControls] = useState(true);
  const [showSourceSelector, setShowSourceSelector] = useState(false);
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
        const sourcesRes = await api.get(sourcesUrl);
        setSources(sourcesRes.data);
        if (sourcesRes.data.length > 0) {
          setSelectedSource(sourcesRes.data[0]);
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
    }, 3000);
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

  if (!movie) return <div className="h-screen bg-black flex items-center justify-center">Loading...</div>;

  const isEmbed = selectedSource?.type === 'embed';

  return (
    <div
      className="fixed inset-0 z-[100] bg-black group"
      onMouseMove={handleMouseMove}
    >
      {/* Back Button */}
      <div className={`absolute top-0 left-0 p-8 z-[110] transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0'}`}>
        <button
          onClick={() => navigate(-1)}
          className="flex items-center space-x-2 text-white hover:text-gray-300 font-bold uppercase tracking-widest text-sm"
        >
          <ArrowLeft size={32} />
          <span>{movie.title} {season && ` - S${season}E${episode}`}</span>
        </button>
      </div>

      {/* Video Content */}
      <div className="w-full h-full">
        {isEmbed ? (
          <iframe
            src={selectedSource.url}
            className="w-full h-full border-none"
            allowFullScreen
            title="Video Player"
          />
        ) : (
          <video
            ref={videoRef}
            src={selectedSource?.url || movie.videoUrl}
            className="w-full h-full cursor-none"
            onTimeUpdate={onTimeUpdate}
            onLoadedMetadata={onLoadedMetadata}
            onClick={togglePlay}
            autoPlay
          />
        )}
      </div>

      {/* Controls Overlay (Only for non-embed) */}
      {!isEmbed && (
        <div className={`absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/20 flex flex-col justify-end p-8 transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0'}`}>

          {/* Progress Bar */}
          <div className="w-full mb-6">
            <input
              type="range"
              min="0"
              max="100"
              value={progress}
              onChange={handleSeek}
              className="w-full h-1 bg-gray-600 rounded-lg appearance-none cursor-pointer accent-purple-600 hover:h-2 transition-all"
            />
            <div className="flex justify-between text-xs mt-2 font-bold font-mono text-white">
              <span>{formatTime(videoRef.current?.currentTime || 0)}</span>
              <span>{formatTime(duration)}</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-8">
              <button onClick={togglePlay} className="text-white hover:scale-110 transition-transform">
                {isPlaying ? <Pause size={36} fill="white" /> : <Play size={36} fill="white" />}
              </button>
              <button onClick={() => videoRef.current.currentTime -= 10} className="text-white hover:scale-110 transition-transform">
                <RotateCcw size={28} />
              </button>
              <button onClick={() => videoRef.current.currentTime += 10} className="text-white hover:scale-110 transition-transform">
                <RotateCw size={28} />
              </button>
              <div className="flex items-center space-x-3 group/vol">
                 <Volume2 size={24} className="text-white" />
                 <input type="range" className="w-0 group-hover/vol:w-20 transition-all accent-white h-1 appearance-none bg-white/30" />
              </div>
            </div>

            <div className="flex items-center space-x-6">
              <button
                onClick={() => setShowSourceSelector(!showSourceSelector)}
                className="text-white hover:text-purple-400 flex items-center space-x-2"
              >
                <Monitor size={24} />
                <span className="text-sm font-bold">{selectedSource?.label || 'Source'}</span>
              </button>
              <button className="text-white hover:rotate-90 transition-transform">
                <Settings size={24} />
              </button>
              <button
                onClick={() => videoRef.current.requestFullscreen()}
                className="text-white hover:scale-110 transition-transform"
              >
                <Maximize size={24} />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Floating Source Selector (For both) */}
      {isEmbed && showControls && (
          <div className="absolute bottom-8 right-8 z-[120]">
             <button
                onClick={() => setShowSourceSelector(!showSourceSelector)}
                className="bg-purple-600 text-white px-4 py-2 rounded-full font-bold flex items-center space-x-2 hover:bg-purple-700 transition-colors shadow-lg"
              >
                <Monitor size={20} />
                <span>Switch Source</span>
              </button>
          </div>
      )}

      {showSourceSelector && (
        <div className="absolute inset-0 bg-black/90 z-[130] flex items-center justify-center p-8">
           <div className="max-w-2xl w-full">
              <h2 className="text-3xl font-black text-white mb-8 italic uppercase tracking-tighter">Select Server</h2>
              <div className="grid grid-cols-2 gap-4">
                 {sources.map((source, index) => (
                    <button
                       key={index}
                       onClick={() => {
                          setSelectedSource(source);
                          setShowSourceSelector(false);
                       }}
                       className={`p-6 rounded-2xl text-left transition-all ${selectedSource?.label === source.label ? 'bg-purple-600 border-2 border-white' : 'bg-zinc-900 border-2 border-zinc-800 hover:border-zinc-700'}`}
                    >
                       <div className="text-white font-black text-xl mb-1">{source.label}</div>
                       <div className="text-zinc-400 text-sm font-bold uppercase tracking-widest">{source.type} • {source.provider}</div>
                    </button>
                 ))}
              </div>
              <button
                onClick={() => setShowSourceSelector(false)}
                className="mt-8 text-zinc-500 hover:text-white font-bold uppercase tracking-widest text-sm"
              >
                 Close
              </button>
           </div>
        </div>
      )}
    </div>
  );
};

export default Player;
