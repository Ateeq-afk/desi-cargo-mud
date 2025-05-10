import { supabase } from './supabase';
import type { Booking } from '@/types';

export async function sendSMS(to: string, message: string) {
  try {
    console.log(`Sending SMS to ${to}: ${message}`);
    
    // In a real implementation, you would:
    // 1. Call your SMS gateway API
    // 2. Store the SMS status in Supabase
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return true;
  } catch (error) {
    console.error('SMS sending failed:', error);
    throw error;
  }
}

export async function sendBookingSMS(booking: Booking) {
  try {
    if (!booking.sender?.mobile || !booking.receiver?.mobile) {
      throw new Error('Sender or receiver mobile number is missing');
    }
    
    // Send to sender
    await sendSMS(
      booking.sender.mobile,
      `Your shipment has been booked with LR number ${booking.lr_number}. Track at: ${window.location.origin}/track/${booking.lr_number}`
    );

    // Send to receiver
    await sendSMS(
      booking.receiver.mobile,
      `A shipment is on its way to you with LR number ${booking.lr_number}. Track at: ${window.location.origin}/track/${booking.lr_number}`
    );

    // Log the SMS sending in the database (in a real implementation)
    console.log('SMS notifications sent successfully for booking:', booking.lr_number);
    
    return true;
  } catch (err) {
    console.error('Failed to send booking SMS:', err);
    throw err;
  }
}

export async function sendStatusUpdateSMS(booking: Booking) {
  try {
    if (!booking.sender?.mobile || !booking.receiver?.mobile) {
      throw new Error('Sender or receiver mobile number is missing');
    }
    
    let statusMessage = '';
    switch (booking.status) {
      case 'in_transit':
        statusMessage = `Your shipment with LR ${booking.lr_number} is now in transit from ${booking.from_branch_details?.name} to ${booking.to_branch_details?.name}.`;
        break;
      case 'delivered':
        statusMessage = `Your shipment with LR ${booking.lr_number} has been delivered successfully.`;
        break;
      case 'cancelled':
        statusMessage = `Your shipment with LR ${booking.lr_number} has been cancelled.`;
        break;
      default:
        statusMessage = `Your shipment with LR ${booking.lr_number} status has been updated to ${booking.status}.`;
    }
    
    // Send to sender
    await sendSMS(booking.sender.mobile, statusMessage);

    // Send to receiver
    await sendSMS(booking.receiver.mobile, statusMessage);

    console.log('Status update SMS sent successfully for booking:', booking.lr_number);
    
    return true;
  } catch (err) {
    console.error('Failed to send status update SMS:', err);
    throw err;
  }
}

export async function sendDeliveryReminderSMS(booking: Booking) {
  try {
    if (!booking.receiver?.mobile) {
      throw new Error('Receiver mobile number is missing');
    }
    
    // Only send for in_transit bookings
    if (booking.status !== 'in_transit') {
      throw new Error('Booking is not in transit');
    }
    
    const message = `Your shipment with LR ${booking.lr_number} will be delivered soon. Please ensure someone is available to receive it.`;
    
    // Send to receiver
    await sendSMS(booking.receiver.mobile, message);

    console.log('Delivery reminder SMS sent successfully for booking:', booking.lr_number);
    
    return true;
  } catch (err) {
    console.error('Failed to send delivery reminder SMS:', err);
    throw err;
  }
}