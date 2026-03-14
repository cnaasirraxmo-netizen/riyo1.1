import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Search, User, LogOut, Menu, X, Bell } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Navbar = ({ onLogout }) => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  React.useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Movies', path: '/?type=movie' },
    { name: 'TV Shows', path: '/?type=tv' },
    { name: 'My List', path: '/my-list' },
  ];

  return (
    <nav className={`fixed top-0 left-0 w-full z-[100] transition-all duration-500 px-6 md:px-12 py-4 ${isScrolled ? 'bg-[#0a0a0a]/90 backdrop-blur-2xl border-b border-white/5 py-3' : 'bg-transparent'}`}>
      <div className="max-w-[100rem] mx-auto flex items-center justify-between">

        {/* Logo */}
        <div className="flex items-center space-x-12">
            <Link to="/" className="flex items-center space-x-2">
                <div className="w-10 h-10 bg-purple-600 rounded-xl flex items-center justify-center rotate-12 shadow-[0_0_20px_rgba(147,51,234,0.5)]">
                    <span className="text-white font-black text-2xl -rotate-12">R</span>
                </div>
                <span className="text-2xl font-black italic tracking-tighter uppercase hidden md:block">Riyo<span className="text-purple-600">Box</span></span>
            </Link>

            {/* Desktop Links */}
            <div className="hidden lg:flex items-center space-x-8">
                {navLinks.map((link) => (
                    <Link
                        key={link.name}
                        to={link.path}
                        className={`text-xs font-black uppercase tracking-[0.2em] transition-all hover:text-purple-500 ${location.pathname === link.path ? 'text-purple-600' : 'text-gray-400'}`}
                    >
                        {link.name}
                    </Link>
                ))}
            </div>
        </div>

        {/* Right Section */}
        <div className="flex items-center space-x-6">
            <div className="hidden md:flex items-center bg-white/5 border border-white/10 rounded-full px-4 py-2 hover:bg-white/10 transition-all group">
                <Search size={18} className="text-gray-500 group-hover:text-purple-500 transition-colors" />
                <input
                    type="text"
                    placeholder="Search titles..."
                    className="bg-transparent border-none focus:ring-0 text-xs font-bold w-40 placeholder:text-gray-600 ml-2"
                    onFocus={() => navigate('/search')}
                />
            </div>

            <button className="text-gray-400 hover:text-white transition-colors relative">
                <Bell size={22} />
                <span className="absolute -top-1 -right-1 w-2 h-2 bg-purple-600 rounded-full"></span>
            </button>

            <div className="relative group">
                <button className="w-10 h-10 rounded-xl bg-purple-600/20 border border-purple-500/30 flex items-center justify-center text-purple-500 overflow-hidden hover:scale-110 transition-all">
                    <User size={20} />
                </button>

                {/* Dropdown */}
                <div className="absolute right-0 top-full mt-4 w-56 bg-[#111] border border-white/10 rounded-2xl p-2 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all shadow-2xl backdrop-blur-3xl">
                    <button
                        onClick={onLogout}
                        className="w-full flex items-center space-x-3 px-4 py-3 rounded-xl hover:bg-red-500/10 text-gray-400 hover:text-red-500 transition-all font-black uppercase tracking-widest text-[10px]"
                    >
                        <LogOut size={16} />
                        <span>Sign Out</span>
                    </button>
                </div>
            </div>

            {/* Mobile Menu Toggle */}
            <button
                className="lg:hidden text-white"
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            >
                {isMobileMenuOpen ? <X /> : <Menu />}
            </button>
        </div>
      </div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isMobileMenuOpen && (
            <motion.div
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                className="absolute top-full left-0 w-full bg-[#0a0a0a] border-b border-white/10 p-8 flex flex-col space-y-6 lg:hidden"
            >
                {navLinks.map((link) => (
                    <Link
                        key={link.name}
                        to={link.path}
                        onClick={() => setIsMobileMenuOpen(false)}
                        className="text-xl font-black uppercase italic tracking-tighter hover:text-purple-600 transition-colors"
                    >
                        {link.name}
                    </Link>
                ))}
            </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
};

export default Navbar;
