import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SubjectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140.w, // Fixed width for horizontal scrolling
        margin: EdgeInsets.only(right: 15.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon Box
            Container(
              height: 45.w,
              width: 45.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(height: 20.h),
            // Text Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}