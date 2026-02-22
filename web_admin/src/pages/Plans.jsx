
import React, { useState, useEffect } from 'react';
import { CreditCard, Plus, Save, Trash2, Smartphone, Download, Monitor, Ban } from 'lucide-react';
import api from '../utils/api';

const Plans = () => {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [currentPlan, setCurrentPlan] = useState({
    name: '',
    price: 0,
    interval: 'monthly',
    devicesAllowed: 1,
    downloadLimit: 0,
    has4K: false,
    hasAds: true
  });

  const fetchPlans = async () => {
    try {
      const res = await api.get('/plans');
      setPlans(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPlans();
  }, []);

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      if (currentPlan._id) {
        await api.put(`/plans/${currentPlan._id}`, currentPlan);
      } else {
        await api.post('/plans', currentPlan);
      }
      setIsEditing(false);
      fetchPlans();
    } catch (err) {
      alert('Failed to save plan');
    }
  };

  return (
    <div className="p-8 pb-24">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-black text-white tracking-tight uppercase">Subscription Plans</h1>
          <p className="text-gray-400 mt-1 font-medium">Configure tier access and regional pricing.</p>
        </div>
        <button
          onClick={() => { setCurrentPlan({ name: '', price: 0, interval: 'monthly', devicesAllowed: 1, downloadLimit: 0, has4K: false, hasAds: true }); setIsEditing(true); }}
          className="bg-[#0ea5e9] text-white px-6 py-3 rounded-2xl font-black shadow-lg shadow-[#0ea5e9]/20 flex items-center hover:bg-[#0284c7] transition-all"
        >
          <Plus size={20} className="mr-2" /> CREATE NEW TIER
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {loading ? (
          <div className="col-span-full py-20 text-center text-gray-500 italic">Syncing plans...</div>
        ) : plans.map((plan) => (
          <div key={plan._id} className="bg-[#1f2937] rounded-3xl border border-white/5 overflow-hidden group hover:border-[#0ea5e9]/50 transition-all shadow-xl">
             <div className="p-8 bg-white/5 border-b border-white/5 relative overflow-hidden">
                <div className="absolute -right-4 -top-4 w-24 h-24 bg-[#0ea5e9]/10 rounded-full blur-2xl"></div>
                <h3 className="text-xl font-black text-[#0ea5e9] uppercase tracking-widest mb-1">{plan.name}</h3>
                <div className="flex items-baseline">
                  <span className="text-4xl font-black text-white">${plan.price}</span>
                  <span className="text-xs text-gray-500 font-bold uppercase ml-1">/ {plan.interval}</span>
                </div>
             </div>
             <div className="p-8 space-y-4">
                <div className="flex items-center text-sm font-bold text-gray-300">
                   <Smartphone size={16} className="mr-3 text-gray-500" /> {plan.devicesAllowed} {plan.devicesAllowed === 1 ? 'Device' : 'Devices'}
                </div>
                <div className="flex items-center text-sm font-bold text-gray-300">
                   <Download size={16} className="mr-3 text-gray-500" /> {plan.downloadLimit === 0 ? 'Unlimited' : plan.downloadLimit} Downloads
                </div>
                <div className="flex items-center text-sm font-bold text-gray-300">
                   <Monitor size={16} className="mr-3 text-gray-500" /> {plan.has4K ? '4K Ultra HD' : 'Full HD 1080p'}
                </div>
                <div className="flex items-center text-sm font-bold text-gray-300">
                   <Ban size={16} className="mr-3 text-gray-500" /> {plan.hasAds ? 'With Advertisements' : 'Ad-Free Experience'}
                </div>
             </div>
             <div className="p-8 pt-0 flex space-x-2">
                <button
                  onClick={() => { setCurrentPlan(plan); setIsEditing(true); }}
                  className="flex-1 py-3 bg-white/5 hover:bg-white/10 text-white font-black rounded-xl text-xs transition-all border border-white/5"
                >
                  EDIT PLAN
                </button>
                <button className="p-3 bg-rose-600/10 hover:bg-rose-600 text-rose-500 hover:text-white rounded-xl transition-all border border-rose-600/20">
                  <Trash2 size={16} />
                </button>
             </div>
          </div>
        ))}
      </div>

      {isEditing && (
        <div className="fixed inset-0 bg-black/90 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <form onSubmit={handleSave} className="bg-[#1f2937] border border-white/10 rounded-3xl max-w-lg w-full overflow-hidden shadow-2xl animate-in zoom-in-95 duration-200">
            <div className="p-8 border-b border-white/5 bg-[#111827]">
              <h2 className="text-2xl font-black text-white uppercase tracking-tight">Configure Tier</h2>
              <p className="text-gray-500 text-sm mt-1">Adjust pricing and features for this plan.</p>
            </div>

            <div className="p-8 space-y-6">
              <div>
                <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Plan Name</label>
                <input
                  type="text"
                  value={currentPlan.name}
                  onChange={(e) => setCurrentPlan({...currentPlan, name: e.target.value})}
                  className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                  placeholder="e.g. PREMIUM"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Monthly Price ($)</label>
                  <input
                    type="number"
                    value={currentPlan.price}
                    onChange={(e) => setCurrentPlan({...currentPlan, price: parseFloat(e.target.value)})}
                    className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                    required
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Interval</label>
                  <select
                    value={currentPlan.interval}
                    onChange={(e) => setCurrentPlan({...currentPlan, interval: e.target.value})}
                    className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                  >
                    <option value="monthly">Monthly</option>
                    <option value="yearly">Yearly</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                 <div>
                    <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Max Devices</label>
                    <input
                      type="number"
                      value={currentPlan.devicesAllowed}
                      onChange={(e) => setCurrentPlan({...currentPlan, devicesAllowed: parseInt(e.target.value)})}
                      className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                    />
                 </div>
                 <div>
                    <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Download Limit</label>
                    <input
                      type="number"
                      value={currentPlan.downloadLimit}
                      onChange={(e) => setCurrentPlan({...currentPlan, downloadLimit: parseInt(e.target.value)})}
                      className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                    />
                    <span className="text-[9px] text-gray-500 italic mt-1 block">Set 0 for unlimited</span>
                 </div>
              </div>

              <div className="flex gap-8 pt-2">
                 <label className="flex items-center space-x-3 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={currentPlan.has4K}
                      onChange={(e) => setCurrentPlan({...currentPlan, has4K: e.target.checked})}
                      className="w-5 h-5 rounded border-white/10 bg-[#111827] text-[#0ea5e9]"
                    />
                    <span className="text-xs font-bold text-gray-300">4K Access</span>
                 </label>
                 <label className="flex items-center space-x-3 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={currentPlan.hasAds}
                      onChange={(e) => setCurrentPlan({...currentPlan, hasAds: e.target.checked})}
                      className="w-5 h-5 rounded border-white/10 bg-[#111827] text-[#0ea5e9]"
                    />
                    <span className="text-xs font-bold text-gray-300">Show Ads</span>
                 </label>
              </div>
            </div>

            <div className="p-8 bg-[#111827] flex gap-4">
              <button
                type="submit"
                className="flex-1 bg-[#0ea5e9] hover:bg-[#0284c7] text-white py-4 rounded-2xl font-black transition-all shadow-lg shadow-[#0ea5e9]/20 uppercase tracking-widest text-xs"
              >
                SAVE TIER CONFIG
              </button>
              <button
                type="button"
                onClick={() => setIsEditing(false)}
                className="flex-1 bg-white/5 hover:bg-white/10 text-white py-4 rounded-2xl font-black transition-all border border-white/5 uppercase tracking-widest text-xs"
              >
                CANCEL
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};

export default Plans;
