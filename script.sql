-- Drop all if exist
DROP TABLE IF EXISTS Users;

DROP TABLE IF EXISTS Lessons;

DROP TABLE IF EXISTS Tests;

DROP TABLE IF EXISTS TestQuestions;

DROP TABLE IF EXISTS UserTestResults;

DROP TABLE IF EXISTS UserQuestionAnswers;

DROP TABLE IF EXISTS Universities;

DROP TABLE IF EXISTS UniversityScores;

DROP TABLE IF EXISTS UserPreferences;

DROP TABLE IF EXISTS UniversityRecommendations;
 
DROP TABLE IF EXISTS LessonTracking;

-- Users table
CREATE TABLE Users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    image_url TEXT,
    role TEXT DEFAULT 'student' -- 'student' or 'tutor'
);

-- Documents / Flashcards table
CREATE TABLE Lessons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    content TEXT,
    subject TEXT,
    content_url TEXT,
    created_by INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users (id)
);

-- Tests / Quizzes table
CREATE TABLE Tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    created_by INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users (id)
);

-- Test questions table
CREATE TABLE TestQuestions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_id INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    option_a TEXT,
    option_b TEXT,
    option_c TEXT,
    option_d TEXT,
    correct_option CHAR(1),
    FOREIGN KEY (test_id) REFERENCES Tests (id)
);

-- User test results table
CREATE TABLE UserTestResults (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    test_id INTEGER NOT NULL,
    score REAL,
    total_questions INTEGER,
    correct_answers INTEGER,
    taken_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users (id),
    FOREIGN KEY (test_id) REFERENCES Tests (id)
);

-- User question answers table - stores individual answers for review
CREATE TABLE UserQuestionAnswers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_result_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    user_answer CHAR(1),
    is_correct BOOLEAN DEFAULT FALSE,
    answered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (test_result_id) REFERENCES UserTestResults (id),
    FOREIGN KEY (question_id) REFERENCES TestQuestions (id)
);

-- Universities table
CREATE TABLE Universities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    location TEXT,
    type TEXT,
    description TEXT
);

-- University historical score table
CREATE TABLE UniversityScores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    university_id INTEGER NOT NULL,
    year INTEGER NOT NULL,
    min_score REAL,
    avg_score REAL,
    max_score REAL,
    FOREIGN KEY (university_id) REFERENCES Universities (id)
);

-- User preferences for university recommendations
CREATE TABLE UserPreferences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    preferred_major TEXT,
    current_score REAL,
    expected_score REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users (id)
);

-- Recommended universities for user
CREATE TABLE UniversityRecommendations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    university_id INTEGER NOT NULL,
    recommended_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users (id),
    FOREIGN KEY (university_id) REFERENCES Universities (id)
);

-- Lesson tracking table - tracks user progress on lessons
CREATE TABLE LessonTracking (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    lesson_id INTEGER NOT NULL,
    is_finished BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users (id),
    FOREIGN KEY (lesson_id) REFERENCES Lessons (id)
);

-- Insert data for Universities table
INSERT INTO
    Universities (
        name,
        location,
        type,
        description
    )
VALUES (
        'Harvard University',
        'USA',
        'Private',
        'Ivy League university located in Cambridge, Massachusetts'
    ),
    (
        'Massachusetts Institute of Technology',
        'USA',
        'Private',
        'Leading research university in Cambridge, Massachusetts'
    ),
    (
        'Stanford University',
        'USA',
        'Private',
        'Elite university in Stanford, California'
    ),
    (
        'Princeton University',
        'USA',
        'Private',
        'Ivy League university in Princeton, New Jersey'
    ),
    (
        'Yale University',
        'USA',
        'Private',
        'Ivy League university in New Haven, Connecticut'
    ),
    (
        'Columbia University',
        'USA',
        'Private',
        'Ivy League university in New York City'
    ),
    (
        'University of Chicago',
        'USA',
        'Private',
        'Research university in Chicago, Illinois'
    ),
    (
        'University of Pennsylvania',
        'USA',
        'Private',
        'Ivy League university in Philadelphia, Pennsylvania'
    ),
    (
        'California Institute of Technology',
        'USA',
        'Private',
        'Science and engineering focused university in Pasadena, California'
    ),
    (
        'Johns Hopkins University',
        'USA',
        'Private',
        'Research university in Baltimore, Maryland'
    ),
    (
        'Vietnam National University, Hanoi',
        'Vietnam',
        'Public',
        'Top national university in Hanoi'
    ),
    (
        'Vietnam National University, Ho Chi Minh City',
        'Vietnam',
        'Public',
        'Top national university in Ho Chi Minh City'
    ),
    (
        'Hanoi University of Science and Technology',
        'Vietnam',
        'Public',
        'Leading technical university in Hanoi'
    ),
    (
        'Ho Chi Minh City University of Technology',
        'Vietnam',
        'Public',
        'Technical university in Ho Chi Minh City'
    ),
    (
        'University of Economics Ho Chi Minh City',
        'Vietnam',
        'Public',
        'Economics university in Ho Chi Minh City'
    ),
    (
        'Foreign Trade University',
        'Vietnam',
        'Public',
        'International trade and business university in Hanoi'
    ),
    (
        'Hanoi National University of Education',
        'Vietnam',
        'Public',
        'Education university in Hanoi'
    ),
    (
        'University of Languages and International Studies',
        'Vietnam',
        'Public',
        'Languages and international studies university in Hanoi'
    ),
    (
        'National Economics University',
        'Vietnam',
        'Public',
        'Economics university in Hanoi'
    ),
    (
        'University of Social Sciences and Humanities',
        'Vietnam',
        'Public',
        'Social sciences university in Ho Chi Minh City'
    );

-- Insert data for UniversityScores table (assuming scores are out of 100 for entrance)
INSERT INTO
    UniversityScores (
        university_id,
        year,
        min_score,
        avg_score,
        max_score
    )
VALUES (1, 2024, 95.0, 98.5, 100.0), -- Harvard
    (2, 2024, 94.0, 98.0, 100.0), -- MIT
    (3, 2024, 93.0, 97.5, 100.0), -- Stanford
    (4, 2024, 92.0, 97.0, 100.0), -- Princeton
    (5, 2024, 91.0, 96.5, 100.0), -- Yale
    (6, 2024, 90.0, 96.0, 100.0), -- Columbia
    (7, 2024, 89.0, 95.5, 100.0), -- UChicago
    (8, 2024, 88.0, 95.0, 100.0), -- UPenn
    (9, 2024, 87.0, 94.5, 100.0), -- Caltech
    (10, 2024, 86.0, 94.0, 100.0), -- Johns Hopkins
    (11, 2024, 85.0, 92.0, 98.0), -- VNU Hanoi
    (12, 2024, 84.0, 91.5, 97.0), -- VNU HCM
    (13, 2024, 83.0, 91.0, 96.0), -- HUST
    (14, 2024, 82.0, 90.5, 95.0), -- HCMUT
    (15, 2024, 81.0, 90.0, 94.0), -- UEH
    (16, 2024, 80.0, 89.5, 93.0), -- FTU
    (17, 2024, 79.0, 89.0, 92.0), -- HNUE
    (18, 2024, 78.0, 88.5, 91.0), -- ULIS
    (19, 2024, 77.0, 88.0, 90.0), -- NEU
    (20, 2024, 76.0, 87.5, 89.0);
-- USSH

-- Insert sample data for Users table (only 2 users)
INSERT INTO
    Users (username, email, image_url)
VALUES (
        'student1',
        'student1@example.com',
        'https://example.com/image1.jpg'
    ),
    (
        'tutor1',
        'tutor1@example.com',
        'https://example.com/image2.jpg'
    );

-- Insert sample data for Lessons table
INSERT INTO
    Lessons (
        title,
        description,
        content,
        content_url,
        created_by
    )
VALUES (
        'Math Notes',
        'Comprehensive notes on algebra and geometry',
        'Algebra basics and formulas',
        'https://example.com/math.pdf',
        2
    ),
    (
        'English Vocabulary',
        'Common English words and their meanings',
        'Word: Hello - Meaning: Greeting',
        'https://example.com/english.json',
        2
    ),
    (
        'Physics Study Guide',
        'In-depth guide on classical and modern physics',
        'Newton laws and mechanics',
        'https://example.com/physics.pdf',
        2
    );

-- Insert sample data for Tests table
INSERT INTO
    Tests (
        title,
        description,
        created_by
    )
VALUES (
        'Basic Math Test',
        'Fundamental algebra and arithmetic',
        2
    ),
    (
        'English Grammar Test',
        'Basic grammar and vocabulary',
        2
    );

-- Insert sample data for TestQuestions table
INSERT INTO
    TestQuestions (
        test_id,
        question_text,
        option_a,
        option_b,
        option_c,
        option_d,
        correct_option
    )
VALUES (
        1,
        'What is 2 + 2?',
        '3',
        '4',
        '5',
        '6',
        'B'
    ),
    (
        1,
        'What is 5 × 3?',
        '12',
        '15',
        '18',
        '20',
        'B'
    ),
    (
        2,
        'Choose the correct word: I ___ a book.',
        'read',
        'reads',
        'reading',
        'readed',
        'A'
    ),
    (
        2,
        'What is the synonym of "happy"?',
        'sad',
        'joyful',
        'angry',
        'tired',
        'B'
    );

-- Insert sample data for UserTestResults table
INSERT INTO
    UserTestResults (
        user_id,
        test_id,
        score,
        total_questions,
        correct_answers
    )
VALUES (1, 1, 100.0, 2, 2),
    (1, 2, 50.0, 2, 1);

-- Insert sample data for UserQuestionAnswers table
INSERT INTO
    UserQuestionAnswers (
        test_result_id,
        question_id,
        user_answer,
        is_correct
    )
VALUES (1, 1, 'B', 1),
    (1, 2, 'B', 1),
    (2, 3, 'A', 1),
    (2, 4, 'A', 0);

-- Insert sample data for UserPreferences table
INSERT INTO
    UserPreferences (
        user_id,
        preferred_major,
        current_score,
        expected_score
    )
VALUES (
        1,
        'Computer Science',
        85.0,
        90.0
    ),
    (1, 'Mathematics', 82.0, 88.0);

-- Insert sample data for UniversityRecommendations table
INSERT INTO
    UniversityRecommendations (user_id, university_id)
VALUES (1, 1),
    (1, 2),
    (1, 11);