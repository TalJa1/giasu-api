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

-- Insert 10 advanced Mathematics lessons suitable for grade 11+


INSERT INTO Lessons (title, description, content, subject, content_url, created_by) VALUES
('Complex Numbers and Roots of Unity',
 'Detailed study of complex numbers focusing on modulus, argument, geometric interpretation, De Moivre''s theorem, and roots of unity with problem-solving techniques suitable for advanced high-school students.',
 '<p><strong>Overview</strong></p>\
<p>This lesson covers complex numbers as points in the plane, polar representation, and the algebraic properties that allow solving higher-degree equations.</p>\
<ul>\
    <li><strong>Polar form:</strong> z = r(cos θ + i sin θ)</li>\
    <li><strong>De Moivre''s theorem:</strong> z^n = r^n (cos nθ + i sin nθ)</li>\
    <li><strong>Roots of unity:</strong> solutions to z^n = 1 and their geometric placement on the unit circle</li>\
</ul>\
<p><strong>Problems</strong></p>\
<ol>\
    <li>Find all complex roots of z^6 = 64 and express them in polar and rectangular forms.</li>\
    <li>Given two complex numbers, derive the locus of points where |z - a| = k|z - b|.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Root_of_unity', 2),

('Sequences, Limits and Monotonicity',
 'Rigorous analysis of sequences: limits, monotonicity, boundedness, subsequences, and classical convergence tests. Includes proofs and challenging tasks involving epsilon-N arguments.',
 '<p><strong>Content</strong></p>\
<p>The lesson presents formal definitions of sequence convergence and techniques to prove limits.</p>\
<ul>\
    <li><strong>Definition:</strong> limit of a sequence (epsilon-N form)</li>\
    <li><strong>Monotone convergence theorem:</strong> bounded monotone sequences converge</li>\
    <li><strong>Techniques:</strong> sandwich theorem, comparison, and induction-based estimates</li>\
</ul>\
<p><strong>Example problems</strong></p>\
<ol>\
    <li>Show that the sequence a_n = n/(n+1) is increasing/decreasing and find its limit.</li>\
    <li>Prove or disprove convergence of b_n = (-1)^n + 1/n and analyze subsequences.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Limit_of_a_sequence,https://en.wikipedia.org/wiki/Monotonic_function', 2),

('Infinite Series and Convergence Tests',
 'Advanced study of infinite series: absolute vs conditional convergence, ratio and root tests, alternation tests, and rearrangement consequences. Applications to power series expansion are included.',
 '<p><strong>Summary</strong></p>\
<p>This lesson explores how to determine convergence of series that appear in advanced problems and contest settings.</p>\
<ul>\
    <li><strong>Absolute convergence</strong> and its implications</li>\
    <li><strong>Alternating series test (Leibniz)</strong></li>\
    <li><strong>Comparison, ratio, and root tests</strong></li>\
</ul>\
<p><strong>Challenging tasks</strong></p>\
<ol>\
    <li>Decide convergence of the series ∑_{n=1}^∞ (-1)^{n} / sqrt(n) and justify your answer.</li>\
    <li>Analyze radius of convergence for ∑ a_n x^n given a_n = n! / n^n.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Series_(mathematics),https://en.wikipedia.org/wiki/Convergence_tests', 2),

('Advanced Trigonometric Identities and Equations',
 'Comprehensive coverage of trigonometric identities including sum-to-product, product-to-sum, multiple-angle formulas, and solving non-trivial trigonometric equations with parameter dependence.',
 '<p><strong>Key topics</strong></p>\
<ul>\
    <li>Sum and difference formulas, double and triple angle formulas</li>\
    <li>Transformations: sum-to-product, product-to-sum</li>\
    <li>Solving parameterized trigonometric equations and inequalities</li>\
</ul>\
<p><strong>Examples</strong></p>\
<ol>\
    <li>Solve for x: 2 sin(2x) + sin(x) = 0 on [0, 2π).</li>\
    <li>Prove that for any real x, sin^2 x + sin^2(x + 2π/3) + sin^2(x + 4π/3) = 3/2.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/List_of_trigonometric_identities,https://en.wikipedia.org/wiki/Trigonometric_functions', 2),

('Definite and Improper Integrals: Techniques and Applications',
 'Deep exploration of definite integrals including substitution, integration by parts, improper integrals, and applications to area, volume, and convergence problems.',
 '<p><strong>Overview</strong></p>\
<p>Focus on rigorous computation and convergence of improper integrals with applied examples.</p>\
<ul>\
    <li>Integration techniques: parts, substitution, trigonometric substitution</li>\
    <li>Improper integrals: classification and convergence criteria</li>\
    <li>Applications: arc length, area between curves, solids of revolution</li>\
</ul>\
<p><strong>Problems</strong></p>\
<ol>\
    <li>Evaluate ∫_0^∞ x^2 e^{-x} dx and justify convergence.</li>\
    <li>Determine whether ∫_1^∞ 1/(x (ln x)^p) dx converges for p &gt; 0 and find the critical exponent.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Improper_integral,https://proofwiki.org/wiki/Definition:Improper_Integral', 2),

('Vectors in Space and Planes',
 'Analytic geometry in three dimensions: vector operations, equations of lines and planes, distances, angles, and intersection problems with rigorous derivations and examples.',
 '<p><strong>Topics</strong></p>\
<ul>\
    <li>Vector operations: dot product, cross product, projection</li>\
    <li>Equation of a line and plane in parametric and Cartesian forms</li>\
    <li>Distances between point-line, point-plane, and angle between planes</li>\
</ul>\
<p><strong>Sample tasks</strong></p>\
<ol>\
    <li>Find intersection line of two non-parallel planes and compute the angle between them.</li>\
    <li>Compute shortest distance from a point to a given line in space.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Vector_space', 2),

('Conic Sections: Focus-Directrix and Reflective Properties',
 'Study of parabola, ellipse, and hyperbola using geometric and analytic definitions, focus-directrix property, eccentricity, and reflective properties used in optics and problem solving.',
 '<p><strong>Content</strong></p>\
<ul>\
    <li>Definitions: conic as locus of points with constant ratio to focus and directrix</li>\
    <li>Standard equations and transformations</li>\
    <li>Reflective property proofs and applications</li>\
</ul>\
<p><strong>Exercises</strong></p>\
<ol>\
    <li>Derive the equation of a conic with given eccentricity and directrix.</li>\
    <li>Prove the reflective property of the parabola using vector or analytic methods.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Conic_section', 2),

('Inequalities: AM-GM, Cauchy, and Jensen',
 'Advanced inequalities and strategies for olympiad-style problems: proof techniques, equality cases, and combining classical inequalities to solve hard problems.',
 '<p><strong>Core concepts</strong></p>\
<ul>\
    <li>Arithmetic mean - Geometric mean inequality and equality conditions</li>\
    <li>Cauchy-Schwarz inequality and its algebraic and geometric interpretations</li>\
    <li>Jensen''s inequality for convex functions and applications</li>\
</ul>\
<p><strong>Problems</strong></p>\
<ol>\
    <li>Use Cauchy-Schwarz to prove (∑ a_i^2)(∑ b_i^2) ≥ (∑ a_i b_i)^2 for real sequences.</li>\
    <li>Solve: For positive x,y,z with xyz = 1, minimize x + y + z.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/AM%E2%80%93GM_inequality', 2),

('Sequences and Power Series: Uniform Convergence',
 'In-depth look at power series, Taylor expansions, and uniform convergence criteria. Emphasis on rigorous justification when interchanging limits and integration or differentiation.',
 '<p><strong>Material</strong></p>\
<ul>\
    <li>Power series center and radius of convergence</li>\
    <li>Uniform vs pointwise convergence; Weierstrass M-test</li>\
    <li>Taylor series and remainder estimates</li>\
</ul>\
<p><strong>Exercises</strong></p>\
<ol>\
    <li>Find radius of convergence for ∑ n^2 x^n and discuss uniform convergence on closed intervals.</li>\
    <li>Use Taylor''s theorem to estimate the remainder for e^x around 0 up to order 3.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Uniform_convergence', 2),

('Matrices, Determinants and Eigenvalues',
 'Fundamental linear algebra with a focus on determinants, eigenvalues, diagonalization, and applications to solving systems and understanding linear transformations at a higher level.',
 '<p><strong>Topics covered</strong></p>\
<ul>\
    <li>Properties of determinants and computation techniques</li>\
    <li>Eigenvalues and eigenvectors; characteristic polynomial</li>\
    <li>Diagonalization criteria and applications to repeated iteration problems</li>\
</ul>\
<p><strong>Problems</strong></p>\
<ol>\
    <li>Compute eigenvalues of a 3x3 matrix with given structure and determine diagonalizability.</li>\
    <li>Use determinants to prove linear independence in parameterized families.</li>\
</ol>',
 'Mathematics', 'https://en.wikipedia.org/wiki/Determinant,https://en.wikipedia.org/wiki/Eigenvalues_and_eigenvectors', 2)
;

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