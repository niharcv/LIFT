//
//  MotivationalQuotes.swift
//  LIFT
//
//

import Foundation

struct WorkoutEncouragement {
    static let messages = [
        "Are you waiting for muscle atrophy to set in? Go lift.",
        "Your couch isn't going to build a chest. Get up.",
        "You haven't worked out in %d days, you lazy fatty.",
        "Your biceps are starting to look like spaghetti. Go train.",
        "Excuses don't burn calories. Get moving.",
        "The gym misses you. Or at least your membership fee. Go lift.",
        "Your water retention is peaking. Stop eating chips and hit the rack.",
        "Is gravity feeling heavier today, or are you just weaker?",
        "Go lift some iron, you soft-shelled crab.",
        "Jeans feeling a bit snug? Stop slacking.",
        "Another day of rest? Who do you think you are, an Olympian?",
        "Don't worry, your excuses will keep you warm when you have no muscle.",
        "Your sweat glands must be dry by now. Let's fix that.",
        "Get up and lift. Those weights won't move themselves, and clearly you aren't either.",
        "Did you cancel your subscription to fitness?",
        "You're a %d-day streak slacker. Go push something heavy.",
        "Sweating is just fat crying. Go make it bawl.",
        "Your reflection in the mirror is judging you. Go train.",
        "Your future self is screaming at you to get up right now.",
        "Put down the phone and pick up the barbell.",
        "Less scrolling, more squatting.",
        "Are you bulking or just collecting dust?",
        "You haven't worked out in %d days. I've seen turtles make faster progress.",
        "Your heart called. It wants some actual cardiovascular work.",
        "You're soft. Go get some calluses.",
        "Remember when you said 'tomorrow'? It's today. Go train.",
        "Stop waiting for inspiration. It's in the gym.",
        "Gym clothes are for working out, not for nap time.",
        "Active rest doesn't mean eating pizza actively.",
        "If you want results, you have to sweat for them. Get up.",
        "You look like you're training for a competitive sleeping league.",
        "Go lift something until your muscles forget your excuses.",
        "Are you waiting for the weights to come to you?",
        "Your heart rate is too low. Move.",
        "Your gym towel is cleaner than my search history. Wash it in sweat.",
        "Stop being a marshmallow. Go lift.",
        "You haven't worked out in %d days. Muscle memory is going to forget you exist.",
        "Is your fitness tracker counting your eye rolls as steps?",
        "Get up and train. Your excuses are exhausted, and so am I.",
        "Gravity is winning. Fight back.",
        "You are %d days away from losing your gains entirely.",
        "Go bench press your problems away.",
        "Stop admiring the dumbbells. Go use them.",
        "You are one workout away from not being a complete disappointment today.",
        "Do you want results or do you want a medal for resting?",
        "No pain, no gains. No workout, no respect.",
        "Go squat. Your legs look like they could be snapped by a strong breeze.",
        "You haven't worked out in %d days. Stop being a couch cushion.",
        "Stop talking about it. Go sweat about it.",
        "Your gym membership card is crying in your wallet. Go scan it.",
        
        // Harsher, savage additions
        "You haven't worked out in %d days. Your doctor is currently drawing up your diabetes management plan. Move.",
        "Your scale is begging for mercy, and you haven't lifted in %d days. Stop grazing.",
        "You haven't worked out in %d days. Are you waiting for a heart attack to start your warm-up?",
        "A bag of flour has more structure than your posture right now. Get off your ass, it's been %d days.",
        "Looking in the mirror must require a lot of courage these days. Go squat.",
        "You haven't trained in %d days. Your muscles are currently converting into pure lard.",
        "At this rate, the only PR you're breaking is the sofa compression index. It's been %d days.",
        "You haven't worked out in %d days. Do you want to remain a soft, doughy disappointment forever?",
        "Your double chin is starting to develop its own postcode. Go lift.",
        "You've been slacking for %d days. Your gym is considering changing your membership status to 'donation'.",
        "Is your target aesthetic 'melted candle'? Because that's what you look like after %d days off.",
        "You haven't worked out in %d days. Stop eating your feelings and go press some heavy metal.",
        "The only heavy lifting you've done in %d days is raising food to your mouth. Get up.",
        "You haven't trained in %d days. Your cardio is currently limited to chewing. Hit the gym.",
        "You're %d days into becoming a potato. Go lift before you sprout.",
        "You haven't worked out in %d days. Even your sweatpants are embarrassed to be seen with you.",
        "You haven't lifted in %d days. Your arms look like wet pool noodles. Do something about it.",
        "Your chest looks like a pair of deflated balloons. Get up and bench, it's been %d days.",
        "You haven't trained in %d days. Do you get winded opening the fridge?",
        "You haven't lifted in %d days. Stop making excuses and go make some sweat.",
        "Your biceps look like they're filled with soft-serve ice cream. Go curl something, it's been %d days.",
        "You haven't worked out in %d days. Are you trying to see how quickly you can dissolve your skeleton?",
        "Laying on the couch for %d days isn't 'recovery', it's hibernation. Go sweat.",
        "You've dodged the gym for %d days. You're starting to look like a sack of laundry.",
        "You haven't lifted in %d days. The only thing toned on your body is your attitude.",
        "At this rate, you won't need weights, gravity will crush you on its own. Move, it's been %d days.",
        "You haven't trained in %d days. I've seen soup cans with better definition than your arms.",
        "You've slacked for %d days. You're a walking, breathing advertisement for inactivity.",
        "You haven't worked out in %d days. Are you planning on rolling to the gym next time?",
        "Your muscles have officially filed a missing persons report. It's been %d days. Find them."
    ]
    
    static func getMessage(daysSinceLastWorkout: Int) -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        // Seed selection with day of year + user's last workout duration to keep it stable per day but unique
        let index = (dayOfYear + daysSinceLastWorkout) % messages.count
        let rawMessage = messages[index]
        return String(format: rawMessage, daysSinceLastWorkout)
    }
}
