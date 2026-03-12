import React from 'react';
import { Bell, Send } from 'lucide-react';

const Notifications = () => (
  <div className="space-y-6">
    <h1 className="text-2xl font-bold text-[#1d2327]">Notification Management</h1>
    <div className="admin-card max-w-2xl">
      <h2 className="text-lg font-bold mb-6">Send Push Notification</h2>
      <form className="space-y-4">
        <div>
          <label className="block text-sm font-bold mb-1">Target Audience</label>
          <select className="input-field w-full">
            <option>All Users</option>
            <option>Premium Users Only</option>
            <option>Inactive Users</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-bold mb-1">Notification Title</label>
          <input type="text" className="input-field w-full" placeholder="e.g. New Movie Released!" />
        </div>
        <div>
          <label className="block text-sm font-bold mb-1">Message Body</label>
          <textarea className="input-field w-full h-24" placeholder="Enter notification message..."></textarea>
        </div>
        <button type="button" className="btn-primary w-full justify-center"><Send size={18} /> Send Notification Now</button>
      </form>
    </div>
  </div>
);

export default Notifications;
