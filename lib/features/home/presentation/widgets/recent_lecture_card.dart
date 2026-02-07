import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class RecentLectureCard extends StatelessWidget {
  final String title;
  final String subject;
  final String timeAgo;
  final String duration;
  final VoidCallback onTap;

  const RecentLectureCard({
    super.key,
    required this.title,
    required this.subject,
    required this.timeAgo,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            height: 45.w,
            width: 45.w,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.microphone, color: Colors.blue, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          // Title & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "$subject • $timeAgo",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Duration
          Row(
            children: [
              Icon(Iconsax.clock, size: 14.sp, color: Colors.grey[400]),
              SizedBox(width: 4.w),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}