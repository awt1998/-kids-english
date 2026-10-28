import '../content/content_repository.dart';
import '../content/models.dart';
import 'child_profile.dart';

/// Stars for a finished lesson. Finishing always earns at least one star:
/// mistakes are part of learning, never a failure.
int starsFor({required int mistakes}) {
  if (mistakes == 0) return 3;
  if (mistakes <= 2) return 2;
  return 1;
}

bool isLessonDone(ChildProfile child, Lesson lesson) =>
    (child.lessonStars[lesson.key] ?? 0) > 0;

bool isUnitDone(ChildProfile child, Unit unit) =>
    unit.isAvailable &&
    ContentRepository.lessonsFor(unit).every((l) => isLessonDone(child, l));

/// A unit opens once every earlier unit is finished. Units without content stay closed.
bool isUnitOpen(ChildProfile child, List<Unit> units, Unit unit) {
  if (!unit.isAvailable) return false;
  final i = units.indexOf(unit);
  return units.take(i).every((u) => isUnitDone(child, u));
}

/// Lessons open one after another inside an open unit.
bool isLessonOpen(ChildProfile child, List<Unit> units, Lesson lesson) {
  if (!isUnitOpen(child, units, lesson.unit)) return false;
  if (lesson.index == 0) return true;
  final previous = ContentRepository.lessonsFor(lesson.unit)[lesson.index - 1];
  return isLessonDone(child, previous);
}

/// The lesson the child should play next (where the mascot waits on the map).
Lesson? nextLesson(ChildProfile child, List<Unit> units) {
  for (final unit in units) {
    for (final lesson in ContentRepository.lessonsFor(unit)) {
      if (isLessonOpen(child, units, lesson) && !isLessonDone(child, lesson)) {
        return lesson;
      }
    }
  }
  return null;
}
