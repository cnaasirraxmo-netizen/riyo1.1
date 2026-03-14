import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Search, User, LogOut, Menu, X, Bell, LayoutGrid, Heart, UserCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Navbar = ({ onLogout }) => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  React.useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { name: 'Discover', path: '/', icon: <LayoutGrid size={16} /> },
    { name: 'Favorites', path: '/my-list', icon: <Heart size={16} /> },
  ];

  return (
    <nav className={`fixed top-0 left-0 w-full z-[100] transition-all duration-700 px-6 md:px-16 py-8 ${isScrolled ? 'bg-[#050505]/80 backdrop-blur-3xl border-b border-white/5 py-5' : 'bg-transparent'}`}>
      <div className="max-w-[120rem] mx-auto flex items-center justify-between">

        {/* Brand Identity */}
        <div className="flex items-center space-x-16">
            <Link to="/" className="flex items-center space-x-3 group">
                <div className="w-12 h-12 bg-purple-600 rounded-2xl flex items-center justify-center rotate-[10deg] group-hover:rotate-0 transition-all duration-500 shadow-[0_10px_30px_rgba(139,92,246,0.5)]">
                    <span className="text-white font-black text-2xl -rotate-[10deg] group-hover:rotate-0 transition-all">R</span>
                </div>
                <div className="flex flex-col leading-none">
                    <span className="text-2xl font-black italic tracking-tighter uppercase text-white">RIYO<span className="text-purple-600">BOX</span></span>
                    <span className="text-[7px] font-black uppercase tracking-[0.6em] text-purple-500/80">Premium Access</span>
                </div>
            </Link>

            {/* Premium Nav Links */}
            <div className="hidden lg:flex items-center space-x-12">
                {navLinks.map((link) => (
                    <Link
                        key={link.name}
                        to={link.path}
                        className={`group flex items-center space-x-2.5 text-[10px] font-black uppercase tracking-[0.3em] transition-all ${location.pathname === link.path ? 'text-purple-500' : 'text-slate-400 hover:text-white'}`}
                    >
                        <span className={`transition-transform duration-500 group-hover:scale-125 ${location.pathname === link.path ? 'text-purple-500' : 'text-slate-600'}`}>
                            {link.icon}
                        </span>
                        <span>{link.name}</span>
                    </Link>
                ))}
            </div>
        </div>

        {/* Global Interaction Hub */}
        <div className="flex items-center space-x-8">
            <div
                onClick={() => navigate('/search')}
                className="hidden md:flex items-center bg-white/5 border border-white/5 rounded-2xl px-6 py-3 hover:bg-white/10 transition-all group cursor-pointer"
            >
                <Search size={18} className="text-slate-500 group-hover:text-purple-500 transition-colors" />
                <span className="text-[10px] font-black uppercase tracking-widest text-slate-600 ml-4">Search Universe...</span>
            </div>

            <button className="text-slate-400 hover:text-white transition-all relative group p-2">
                <Bell size={24} className="group-hover:rotate-12 transition-transform" />
                <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-purple-600 rounded-full border-2 border-[#050505] shadow-[0_0_15px_rgba(139,92,246,0.8)]"></span>
            </button>

            <div className="relative group">
                <button className="w-12 h-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-slate-400 overflow-hidden hover:border-purple-500/50 hover:text-purple-500 transition-all shadow-xl">
                    <UserCircle size={28} strokeWidth={1.5} />
                </button>

                {/* Cinematic Dropdown */}
                <div className="absolute right-0 top-full mt-6 w-64 glass-dark rounded-[2rem] p-4 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-500 shadow-[0_40px_100px_rgba(0,0,0,0.6)] border border-white/10 origin-top-right scale-95 group-hover:scale-100">
                    <div className="px-4 py-6 border-b border-white/5 mb-2">
                        <div className="text-[8px] font-black uppercase tracking-[0.4em] text-purple-500 mb-1">Authenticated User</div>
                        <div className="text-sm font-black text-white truncate italic uppercase">Member #RIYO2024</div>
                    </div>
                    <button
                        onClick={onLogout}
                        className="w-full flex items-center justify-between px-6 py-4 rounded-2xl hover:bg-red-500/10 text-slate-400 hover:text-red-500 transition-all font-black uppercase tracking-widest text-[9px]"
                    >
                        <span>Terminate Session</span>
                        <LogOut size={16} />
                    </button>
                </div>
            </div>

            {/* Mobile Interface Toggle */}
            <button
                className="lg:hidden p-3 glass rounded-xl text-white"
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            >
                {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
            </button>
        </div>
      </div>

      {/* Luxury Mobile Overlay */}
      <AnimatePresence>
        {isMobileMenuOpen && (
            <motion.div
                initial={{ opacity: 0, x: 100 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 100 }}
                className="fixed inset-0 top-0 left-0 w-full h-screen bg-[#050505] z-[200] p-12 flex flex-col justify-center items-center space-y-12 lg:hidden"
            >
                <button onClick={() => setIsMobileMenuOpen(false)} className="absolute top-10 right-10 p-4 bg-white/5 rounded-full text-white">
                    <X size={32} />
                </button>

                {navLinks.map((link) => (
                    <Link
                        key={link.name}
                        to={link.path}
                        onClick={() => setIsMobileMenuOpen(false)}
                        className="text-6xl font-black uppercase italic tracking-tighter hover:text-purple-600 transition-all transform hover:scale-110"
                    >
                        {link.name}
                    </Link>
                ))}

                <button
                    onClick={onLogout}
                    className="mt-12 text-red-500 font-black uppercase tracking-[0.5em] text-xs"
                >
                    Terminte Session
                </button>
            </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
};

export default Navbar;
