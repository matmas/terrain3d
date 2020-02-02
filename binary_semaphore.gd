extends Reference
class_name BinarySemaphore
"""
A Semaphore with maxumum value of 1.

Use cases for the binary semaphore include rate-limiting threads with timers
without the thread trying to catch up with the timer in case the thread
execution gets delayed.
"""

var semaphore := Semaphore.new()
var mutex := Mutex.new()
var is_zero = true


func post():
	mutex.lock()
	is_zero = false
	mutex.unlock()

	semaphore.post()


func wait():
	while true:
		semaphore.wait()

		mutex.lock()
		var _is_zero = is_zero
		mutex.unlock()

		if not _is_zero:
			break

	mutex.lock()
	is_zero = true
	mutex.unlock()
