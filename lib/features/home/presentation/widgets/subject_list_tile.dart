import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class SubjectListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lectureCount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const SubjectListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lectureCount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Colorful Icon Box
          Container(
            height: 50.w,
            width: 50.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 15.w),

          // 2. Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "$lectureCount LECTURES",
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: color, // Text color matches icon color
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // 3. Arrow Icon
          Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey[300]),
        ],
      ),
    );
  }
}