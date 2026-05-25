import '../models/review_event.dart';

abstract class ReviewRepository {
  Future<void> recordReviewEvent(ReviewEvent event);
}
