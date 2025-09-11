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

DROP TABLE IF EXISTS Quizlet;

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
    -- If true, this test may include questions that allow multiple answers.
    supports_multiple_answers BOOLEAN DEFAULT FALSE,
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
    -- question_type: 'single' or 'multiple'
    question_type TEXT NOT NULL DEFAULT 'single',
    -- correct_options stores one or more correct choices. Use a JSON array or comma-separated letters, e.g. '["A"]' or 'A,B'
    correct_options TEXT,
    -- points available for this question (useful for partial credit)
    points REAL DEFAULT 1.0,
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
    -- optional: support point-based scoring for partial credit
    points_earned REAL DEFAULT 0.0,
    points_possible REAL DEFAULT 0.0,
    taken_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users (id),
    FOREIGN KEY (test_id) REFERENCES Tests (id)
);

-- User question answers table - stores individual answers for review
CREATE TABLE UserQuestionAnswers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_result_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    -- user_answer can store single choice like 'A' or multiple like '["A","C"]' or 'A,C'
    user_answer TEXT,
    is_correct BOOLEAN DEFAULT FALSE,
    -- fraction or points awarded for this answer (useful for partial credit on multiple-choice)
    partial_credit REAL DEFAULT 0.0,
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

-- Quizlet table - stores simple question & answer pairs linked to a lesson
CREATE TABLE Quizlet (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lesson_id INTEGER NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
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
        'Lesson 1 Test - Complex Numbers',
        'Test covering Complex Numbers and Roots of Unity',
        2
    ),
    (
        'Lesson 2 Test - Sequences and Limits',
        'Test covering Sequences, Limits and Monotonicity',
        2
    ),
    (
        'Lesson 3 Test - Infinite Series',
        'Test covering Infinite Series and Convergence Tests',
        2
    ),
    (
        'Lesson 4 Test - Trigonometry',
        'Test covering Advanced Trigonometric Identities and Equations',
        2
    ),
    (
        'Lesson 5 Test - Integrals',
        'Test covering Definite and Improper Integrals',
        2
    ),
    (
        'Lesson 6 Test - Vectors',
        'Test covering Vectors in Space and Planes',
        2
    ),
    (
        'Lesson 7 Test - Conic Sections',
        'Test covering Conic Sections and Properties',
        2
    ),
    (
        'Lesson 8 Test - Inequalities',
        'Test covering AM-GM, Cauchy, Jensen and related problems',
        2
    ),
    (
        'Lesson 9 Test - Power Series',
        'Test covering Sequences and Power Series: Uniform Convergence',
        2
    ),
    (
        'Lesson 10 Test - Linear Algebra',
        'Test covering Matrices, Determinants and Eigenvalues',
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
        question_type,
        correct_options,
        points
    )
VALUES
    -- Test 1 (Lesson 1) questions
    (
        1,
        'Polar form: z = r(cos θ + i sin θ). What is r for z = 3 + 4i?',
        '3',
        '4',
        '5',
        '7',
        'single',
        '["C"]',
        1.0
    ),
    (
        1,
        'De Moivre: (cos θ + i sin θ)^2 equals?',
        'cos2θ + i sin2θ',
        'cos2θ - i sin2θ',
        'cos^2 θ - sin^2 θ + i 2 sin θ cos θ',
        '1',
        'single',
        '["C"]',
        1.0
    ),
    (
        1,
        'Roots of unity: which of the following are 4th roots of unity? (choose all that apply)',
        '1',
        '-1',
        'i',
        '2',
        'multiple',
        '["A","B","C"]',
        1.0
    ),
    (
        1,
        'Convert to rectangular: r=2, θ=π/6 => x = ?',
        '√3',
        '1',
        '2√3',
        '1/2',
        'single',
        '["A"]',
        1.0
    ),
    (
        1,
        'Which statement about complex conjugates is true?',
        'Product of conjugates is sum of squares',
        'Conjugate of sum is sum of conjugates',
        'Conjugate of product is division of conjugates',
        'Conjugate equals negative',
        'single',
        '["B"]',
        1.0
    ),
    (
        1,
        'Find arguments: which angles correspond to roots evenly spaced on unit circle? (choose all)',
        '0',
        'π/2',
        'π/3',
        '2π/3',
        'multiple',
        '["A","B","C","D"]',
        1.0
    ),
    (
        1,
        'If z^6 = 64, what is modulus r?',
        '1',
        '2',
        '4',
        '8',
        'single',
        '["B"]',
        1.0
    ),
    (
        1,
        'Which are valid polar representations of same z? (choose all)',
        'r=2, θ=π/4',
        'r=-2, θ=5π/4',
        'r=2, θ=9π/4',
        'r=2, θ=-7π/4',
        'multiple',
        '["A","C","D"]',
        1.0
    ),
    (
        1,
        'What is geometric interpretation of multiplication by i?',
        'Rotation by 90°',
        'Scaling by 2',
        'Reflection',
        'Translation',
        'single',
        '["A"]',
        1.0
    ),
    (
        1,
        'Which properties hold for modulus |z|? (choose all)',
        'Nonnegative',
        'Multiplicative: |zw|=|z||w|',
        'Additive: |z+w|=|z|+|w|',
        'Triangle inequality',
        'multiple',
        '["A","B","D"]',
        1.0
    ),

-- Test 2 (Lesson 2) questions
(
    2,
    'Limit: what is lim_{n→∞} n/(n+1)?',
    '0',
    '1',
    '∞',
    'Does not exist',
    'single',
    '["B"]',
    1.0
),
(
    2,
    'Monotone convergence theorem applies to which sequences?',
    'Bounded monotone',
    'Any monotone',
    'Any bounded',
    'Periodic',
    'single',
    '["A"]',
    1.0
),
(
    2,
    'Definition: epsilon-N is used to formalize which concept?',
    'Derivative',
    'Integral',
    'Limit of sequence',
    'Continuity',
    'single',
    '["C"]',
    1.0
),
(
    2,
    'Subsequences: b_n = (-1)^n + 1/n has subsequence limits?',
    'Only 1',
    'Only -1',
    '1 and -1',
    'No limits',
    'single',
    '["C"]',
    1.0
),
(
    2,
    'Which are examples of bounded sequences? (choose all)',
    'sin n',
    'n',
    '1/n',
    '(-1)^n',
    'multiple',
    '["A","C","D"]',
    1.0
),
(
    2,
    'Which technique proves monotonicity?',
    'Epsilon-N',
    'Induction',
    'Integration',
    'Matrix diagonalization',
    'single',
    '["B"]',
    1.0
),
(
    2,
    'Which statements correct about subsequences? (choose all)',
    'Every sequence has monotone subsequence',
    'Cauchy implies convergent in R',
    'Subsequence of convergent sequence converges to same limit',
    'A subsequence can diverge if original converges',
    'multiple',
    '["B","C"]',
    1.0
),
(
    2,
    'Given a_n = n/(n+1), is it increasing or decreasing?',
    'Increasing',
    'Decreasing',
    'Constant',
    'Oscillatory',
    'single',
    '["A"]',
    1.0
),
(
    2,
    'Limit comparison is used for sequences or series?',
    'Sequences',
    'Series',
    'Both',
    'Neither',
    'single',
    '["B"]',
    1.0
),
(
    2,
    'Epsilon-N quantifier: For every ε>0 there exists N such that...',
    'For all n≥N |a_n-L|<ε',
    'There exists n |a_n-L|>ε',
    'L depends on n',
    'ε depends on N',
    'single',
    '["A"]',
    1.0
),

-- Test 3 (Lesson 3) questions
(
    3,
    'Absolute convergence: series ∑ a_n absolutely convergent means?',
    '∑ a_n converges',
    '∑ |a_n| converges',
    'Terms go to zero',
    '∑ (-1)^n a_n converges',
    'single',
    '["B"]',
    1.0
),
(
    3,
    'Alternating series test requires what?',
    'Terms nonincreasing to 0',
    'Terms increasing',
    'Absolute convergence',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    3,
    'Does ∑ (-1)^n / sqrt(n) converge?',
    'Yes (conditional)',
    'No',
    'Yes (absolute)',
    'Diverges to ∞',
    'single',
    '["A"]',
    1.0
),
(
    3,
    'Which tests are useful for factorial growth? (choose all)',
    'Ratio test',
    'Root test',
    'Alternating test',
    'Comparison with p-series',
    'multiple',
    '["A","B"]',
    1.0
),
(
    3,
    'Radius of convergence uses which value?',
    'Sum of coefficients',
    'limsup |a_n|^{1/n}',
    'Product of terms',
    'First term only',
    'single',
    '["B"]',
    1.0
),
(
    3,
    'Which are consequences of absolute convergence? (choose all)',
    'Rearrangements preserve sum',
    'Series converges absolutely',
    'Conditional convergence',
    'Uniform convergence',
    'multiple',
    '["A","B"]',
    1.0
),
(
    3,
    'Power series center affects what?',
    'Radius',
    'Interval of convergence center',
    'Coefficients',
    'Degree',
    'single',
    '["B"]',
    1.0
),
(
    3,
    'Which is a necessary condition for series convergence?',
    'Terms → 0',
    'Partial sums bounded',
    'Absolute convergence',
    'Alternation',
    'single',
    '["A"]',
    1.0
),
(
    3,
    'Use of root test is best when terms involve which form?',
    'n!',
    'a^n',
    'n^n',
    'log n',
    'multiple',
    '["B","C"]',
    1.0
),
(
    3,
    'Which statements about conditional convergence are true? (choose all)',
    'Absolute divergence possible',
    'Sum depends on order',
    'Always converges absolutely',
    'None',
    'multiple',
    '["A","B"]',
    1.0
),

-- Test 4 (Lesson 4) questions
(
    4,
    'Double-angle: sin 2x equals?',
    '2 sin x cos x',
    'sin^2 x - cos^2 x',
    'tan x',
    '2 cos^2 x',
    'single',
    '["A"]',
    1.0
),
(
    4,
    'Sum-to-product: sin A + sin B equals?',
    '2 sin((A+B)/2) cos((A-B)/2)',
    'sin(A+B)',
    'cos(A-B)',
    '2 cos((A+B)/2) sin((A-B)/2)',
    'single',
    '["A"]',
    1.0
),
(
    4,
    'Which identities are triple-angle formulas? (choose all)',
    'cos3x=4cos^3x-3cosx',
    'sin3x=3sinx-4sin^3x',
    'tan3x formula',
    'None',
    'multiple',
    '["A","B","C"]',
    1.0
),
(
    4,
    'Solve: 2 sin(2x)+sin x=0 technique uses?',
    'Double-angle identity',
    'Integration',
    'Complex numbers',
    'Differentiation',
    'single',
    '["A"]',
    1.0
),
(
    4,
    'Value of sin^2 x + sin^2(x+2π/3)+sin^2(x+4π/3) equals?',
    '1',
    '3/2',
    '2',
    '0',
    'single',
    '["B"]',
    1.0
),
(
    4,
    'Which are transformations turning sums into products? (choose all)',
    'Product-to-sum',
    'Sum-to-product',
    'Double-angle',
    'Half-angle',
    'multiple',
    '["B","A"]',
    1.0
),
(
    4,
    'Triple-angle cosine formula equals?',
    'cos3x=4cos^3x-3cosx',
    'cos3x=3cosx-4cos^3x',
    'cos3x=cos x',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    4,
    'Which methods help solve parameterized trig equations? (choose all)',
    'Graphical',
    'Algebraic identities',
    'Numerical only',
    'Symmetry arguments',
    'multiple',
    '["A","B","D"]',
    1.0
),
(
    4,
    'Sum-to-product formula helps convert sums into what?',
    'Products',
    'Integrals',
    'Derivatives',
    'Matrices',
    'single',
    '["A"]',
    1.0
),
(
    4,
    'Which is a valid double-angle identity for cosine?',
    'cos2x=cos^2x-sin^2x',
    'cos2x=2cosx',
    'cos2x=sinx',
    'cos2x=1',
    'single',
    '["A"]',
    1.0
),

-- Test 5 (Lesson 5) questions
(
    5,
    'Evaluate ∫_0^∞ x^2 e^{-x} dx equals?',
    '1',
    '2',
    'Γ(3)=2',
    '∞',
    'single',
    '["C"]',
    1.0
),
(
    5,
    'Improper integral ∫_1^∞ 1/(x (ln x)^p) converges for which p?',
    'p>0',
    'p>1',
    'p<1',
    'all p',
    'single',
    '["B"]',
    1.0
),
(
    5,
    'Integration by parts formula is?',
    '∫ u dv = uv - ∫ v du',
    '∫ u dv = u+v',
    '∫ u dv = uv',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    5,
    'What is an improper integral?',
    'Integral with infinite limits or singularities',
    'Integral of polynomial',
    'Definite integral only',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    5,
    'Test convergence for improper integrals using which methods? (choose all)',
    'Comparison',
    'Limit comparison',
    'Integration by parts',
    'Ratio test',
    'multiple',
    '["A","B"]',
    1.0
),
(
    5,
    'Which substitution is useful for ∫ x^2 e^{-x} dx?',
    'u=x',
    'u=e^{-x}',
    'Gamma substitution',
    'Trigonometric',
    'single',
    '["C"]',
    1.0
),
(
    5,
    'What justifies interchange of limit and integral?',
    'Uniform convergence',
    'Pointwise convergence',
    'Divergence',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    5,
    'Which integrals are improper? (choose all)',
    'Infinite interval',
    'Integrand singular at point',
    'Definite integral with continuous integrand',
    'None',
    'multiple',
    '["A","B"]',
    1.0
),
(
    5,
    'Value of Γ(n) for integer n is?',
    'n',
    'n!',
    '(n-1)!',
    '1',
    'single',
    '["C"]',
    1.0
),
(
    5,
    'Test to determine convergence of ∫_1^∞ 1/(x^p) requires p?',
    'p>1',
    'p<1',
    'p=1',
    'none',
    'single',
    '["A"]',
    1.0
),

-- Test 6 (Lesson 6) questions
(
    6,
    'Dot product a·b equals?',
    '|a||b|cosθ',
    '|a||b|sinθ',
    'Cross product magnitude',
    'Sum of components',
    'single',
    '["A"]',
    1.0
),
(
    6,
    'Cross product gives?',
    'Scalar',
    'Vector orthogonal to both',
    'Angle',
    'None',
    'single',
    '["B"]',
    1.0
),
(
    6,
    'Equation of a plane given point r0 and normal n is?',
    'n·(r - r0) = 0',
    'r·n = r0',
    'r = r0',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    6,
    'Distance from point to plane uses which formula?',
    '|n·(r0 - r)|/|n|',
    'Dot product only',
    'Cross product only',
    'Projection only',
    'single',
    '["A"]',
    1.0
),
(
    6,
    'Find intersection of two planes results in?',
    'Point',
    'Line',
    'Plane',
    'Empty set',
    'single',
    '["B"]',
    1.0
),
(
    6,
    'Which are vector operations? (choose all)',
    'Dot product',
    'Cross product',
    'Matrix multiplication',
    'Scalar division',
    'multiple',
    '["A","B"]',
    1.0
),
(
    6,
    'Projection formula gives which result?',
    'Scalar only',
    'Vector projection',
    'Matrix',
    'Angle',
    'single',
    '["B"]',
    1.0
),
(
    6,
    'Shortest distance from point to line uses which technique?',
    'Projection',
    'Integration',
    'Differentiation',
    'Series expansion',
    'single',
    '["A"]',
    1.0
),
(
    6,
    'Angle between planes equals angle between which vectors?',
    'Normal vectors',
    'Direction vectors',
    'Points',
    'Lines',
    'single',
    '["A"]',
    1.0
),
(
    6,
    'Which statements about cross product are true? (choose all)',
    'Anticommutative',
    'Distributive over addition',
    'Associative',
    'Produces scalar',
    'multiple',
    '["A","B"]',
    1.0
),

-- Test 7 (Lesson 7) questions
(
    7,
    'Definition: conic using focus and directrix depends on which parameter?',
    'Radius',
    'Eccentricity e',
    'Angle',
    'None',
    'single',
    '["B"]',
    1.0
),
(
    7,
    'Eccentricity of parabola equals?',
    '0',
    '1',
    '>1',
    '<1',
    'single',
    '["B"]',
    1.0
),
(
    7,
    'Standard ellipse equation centered at origin is?',
    'x^2/a^2 + y^2/b^2 = 1',
    'x^2 + y^2 = r^2',
    'xy=1',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    7,
    'Reflective property of parabola means rays from focus reflect to?',
    'A point',
    'Parallel to axis',
    'Circle',
    'Ellipse',
    'single',
    '["B"]',
    1.0
),
(
    7,
    'Hyperbola eccentricity condition is?',
    'e<1',
    'e=1',
    'e>1',
    'e=0',
    'single',
    '["C"]',
    1.0
),
(
    7,
    'Which are conic sections? (choose all)',
    'Parabola',
    'Ellipse',
    'Hyperbola',
    'Circle',
    'multiple',
    '["A","B","C","D"]',
    1.0
),
(
    7,
    'Focus-directrix property involves ratio of distances equal to?',
    'e',
    '1/e',
    'e^2',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    7,
    'Which property is used in optics for parabolas?',
    'Reflective property',
    'Rotational symmetry',
    'Translational symmetry',
    'Scaling',
    'single',
    '["A"]',
    1.0
),
(
    7,
    'Ellipse eccentricity relation uses which? (choose all)',
    'b^2=a^2(1-e^2)',
    'b^2=a^2(e^2-1)',
    'Depends on focus',
    'None',
    'multiple',
    '["A"]',
    1.0
),
(
    7,
    'Which transforms convert conic equation orientation?',
    'Rotation of axes',
    'Scaling only',
    'Translation only',
    'Differentiation',
    'single',
    '["A"]',
    1.0
),

-- Test 8 (Lesson 8) questions
(
    8,
    'AM-GM for two positives a and b states?',
    '(a+b)/2 ≥ √(ab)',
    'a+b ≥ ab',
    'a^2+b^2 ≥ 2ab',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    8,
    'Cauchy-Schwarz inequality formula involves which sums?',
    '(Σ a_i^2)(Σ b_i^2) ≥ (Σ a_i b_i)^2',
    'Σ a_i b_i ≥ 0',
    'Product less than sum',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    8,
    'When equality holds in AM-GM?',
    'When variables are equal',
    'When variables are different',
    'Never',
    'Always',
    'single',
    '["A"]',
    1.0
),
(
    8,
    'Jensen''s inequality applies to which functions?',
    'Convex functions',
    'Concave',
    'Linear only',
    'Polynomial only',
    'single',
    '["A"]',
    1.0
),
(
    8,
    'Which inequalities are useful together? (choose all)',
    'AM-GM',
    'Cauchy',
    'Jensen',
    'None',
    'multiple',
    '["A","B","C"]',
    1.0
),
(
    8,
    'For xyz=1 minimize x+y+z by AM-GM gives?',
    '3',
    '1',
    '0',
    'Depends',
    'single',
    '["A"]',
    1.0
),
(
    8,
    'Which are true about Cauchy-Schwarz? (choose all)',
    'Equality when vectors proportional',
    'Used for sequences',
    'Only for positive numbers',
    'None',
    'multiple',
    '["A","B"]',
    1.0
),
(
    8,
    'Using AM-GM can help solve which problems?',
    'Optimization',
    'Integration',
    'Series convergence',
    'Matrix diagonalization',
    'single',
    '["A"]',
    1.0
),
(
    8,
    'Jensen''s inequality requires which property of function?',
    'Convexity',
    'Differentiability',
    'Boundedness',
    'Periodicity',
    'single',
    '["A"]',
    1.0
),
(
    8,
    'Combine inequalities to handle which cases? (choose all)',
    'Equality cases',
    'Upper bounds',
    'Lower bounds',
    'None',
    'multiple',
    '["A","B","C"]',
    1.0
),

-- Test 9 (Lesson 9) questions
(
    9,
    'Uniform convergence of f_n to f means which?',
    'Pointwise only',
    'Uniform: ∀ε ∃N such that ∀n≥N ∀x |f_n-f|<ε',
    'Only at one point',
    'None',
    'single',
    '["B"]',
    1.0
),
(
    9,
    'Weierstrass M-test condition requires which?',
    '|f_n(x)| ≤ M_n and Σ M_n converges',
    'Pointwise bounds',
    'Uniform divergence',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    9,
    'Radius of convergence R equals?',
    'Distance from center where series converges',
    'Sum of coefficients',
    'First coefficient',
    'Degree',
    'single',
    '["A"]',
    1.0
),
(
    9,
    'Does ∑ n^2 x^n have radius 1?',
    'Yes',
    'No',
    'Depends',
    'Infinite',
    'single',
    '["A"]',
    1.0
),
(
    9,
    'Uniform vs pointwise: which justifies interchange of limit and integral?',
    'Uniform',
    'Pointwise',
    'Neither',
    'Both',
    'single',
    '["A"]',
    1.0
),
(
    9,
    'Weierstrass M-test gives what conclusion? (choose all)',
    'Uniform convergence',
    'Absolute convergence of series of functions',
    'Divergence',
    'None',
    'multiple',
    '["A","B"]',
    1.0
),
(
    9,
    'Power series center changes which property?',
    'Center only',
    'Radius',
    'Coefficients',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    9,
    'Uniform convergence on closed interval implies?',
    'Can interchange limit and integral',
    'Divergence',
    'No pointwise convergence',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    9,
    'Which tests find radius of convergence? (choose all)',
    'Ratio test',
    'Root test',
    'Comparison test',
    'Alternating test',
    'multiple',
    '["A","B"]',
    1.0
),
(
    9,
    'Uniform convergence requires which quantifier ordering?',
    '∀ε ∃N ∀n∀x',
    '∃ε ∀N ∀n',
    '∀x ∃N ∀n',
    'None',
    'single',
    '["A"]',
    1.0
),

-- Test 10 (Lesson 10) questions
(
    10,
    'Characteristic polynomial of A is?',
    'det(A - λI)',
    'trace(A)',
    'rank(A)',
    'det(A + λI)',
    'single',
    '["A"]',
    1.0
),
(
    10,
    'Matrix is diagonalizable when?',
    'Has n distinct eigenvectors forming basis',
    'Has determinant 0',
    'Has inverse',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    10,
    'Determinant tells invertibility how?',
    'Invertible iff determinant ≠ 0',
    'Invertible iff det = 0',
    'No relation',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    10,
    'Eigenvalues are roots of which polynomial?',
    'Characteristic polynomial',
    'Minimal polynomial',
    'Any polynomial',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    10,
    'Trace relates to eigenvalues how?',
    'Product of eigenvalues',
    'Sum of eigenvalues',
    'Maximum eigenvalue',
    'Minimum eigenvalue',
    'single',
    '["B"]',
    1.0
),
(
    10,
    'Which are methods to compute determinant? (choose all)',
    'Laplace expansion',
    'Row reduction',
    'Eigen decomposition',
    'Graph algorithms',
    'multiple',
    '["A","B"]',
    1.0
),
(
    10,
    'Which statements about eigenvectors are true? (choose all)',
    'Associated to eigenvalue',
    'Linearly independent if distinct eigenvalues',
    'Always orthogonal',
    'Never zero',
    'multiple',
    '["A","B","D"]',
    1.0
),
(
    10,
    'Diagonalization helps solve which problems?',
    'Systems of ODEs',
    'Integrals',
    'Series',
    'Probability',
    'single',
    '["A"]',
    1.0
),
(
    10,
    'Characteristic polynomial degree equals?',
    'n for n×n matrix',
    '1',
    'Depends',
    'None',
    'single',
    '["A"]',
    1.0
),
(
    10,
    'Which are invariant under similarity transform? (choose all)',
    'Trace',
    'Determinant',
    'Eigenvalues',
    'Rows',
    'multiple',
    '["A","B","C"]',
    1.0
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
        is_correct,
        partial_credit
    )
VALUES (1, 1, '["B"]', 1, 1.0),
    (1, 2, '["B"]', 1, 1.0),
    (2, 3, '["A"]', 1, 1.0),
    (2, 4, '["A"]', 0, 0.0);

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

-- Insert sample Quizlet Q&A for each lesson (approx 5 per lesson)
-- Lesson IDs correspond to the order they were inserted above (1..10)
INSERT INTO
    Quizlet (lesson_id, question, answer)
VALUES
    -- Lesson 1: Complex Numbers and Roots of Unity (lesson_id = 1)
    (
        1,
        'What is the polar form of a complex number z = x + iy?',
        'z = r(cos θ + i sin θ), where r = √(x^2 + y^2) and θ = atan2(y,x)'
    ),
    (
        1,
        'State De Moivre''s theorem for integer n.',
        'z^n = r^n (cos(nθ) + i sin(nθ)) for z = r(cos θ + i sin θ)'
    ),
    (
        1,
        'What are the 6th roots of 64 in polar form?',
        'r = 2 and angles θ_k = (2πk)/6 for k=0..5'
    ),
    (
        1,
        'Where are the nth roots of unity located?',
        'Evenly spaced on the unit circle at angles 2πk/n'
    ),
    (
        1,
        'How to convert from polar to rectangular coordinates?',
        'x = r cos θ, y = r sin θ'
    ),
    -- Lesson 2: Sequences, Limits and Monotonicity (lesson_id = 2)
    (
        2,
        'What is the limit of a_n = n/(n+1)?',
        '1'
    ),
    (
        2,
        'Give the epsilon-N definition of the limit of a sequence.',
        'For every ε>0 there exists N such that for all n≥N, |a_n - L| < ε'
    ),
    (
        2,
        'What does monotone convergence theorem state?',
        'A bounded monotone sequence converges'
    ),
    (
        2,
        'Is b_n = (-1)^n + 1/n convergent?',
        'No, but its subsequences converge to 1 and -1 respectively'
    ),
    (
        2,
        'What is a subsequence?',
        'A sequence formed by selecting terms from the original sequence in increasing index order'
    ),
    -- Lesson 3: Infinite Series and Convergence Tests (lesson_id = 3)
    (
        3,
        'What is absolute convergence?',
        'A series ∑ a_n is absolutely convergent if ∑ |a_n| converges'
    ),
    (
        3,
        'State the alternating series test (Leibniz).',
        'If terms decrease to 0 in absolute value, the alternating series converges'
    ),
    (
        3,
        'Does ∑ (-1)^n / sqrt(n) converge?',
        'Yes, by alternating series test (terms → 0 and decrease in magnitude)'
    ),
    (
        3,
        'What test is useful for factorial growth like n!?',
        'Ratio test'
    ),
    (
        3,
        'Define radius of convergence for power series ∑ a_n x^n.',
        'R = 1/limsup |a_n|^{1/n} (or from ratio/root tests)'
    ),
    -- Lesson 4: Advanced Trigonometric Identities and Equations (lesson_id = 4)
    (
        4,
        'Write the double-angle formula for sine.',
        'sin 2x = 2 sin x cos x'
    ),
    (
        4,
        'Transform sum to product: sin A + sin B.',
        '2 sin((A+B)/2) cos((A-B)/2)'
    ),
    (
        4,
        'What is sin^2 x + sin^2(x+2π/3) + sin^2(x+4π/3)?',
        '3/2'
    ),
    (
        4,
        'Solve 2 sin(2x) + sin x = 0 on [0,2π).',
        'Use identity sin2x = 2 sin x cos x and factor to find solutions'
    ),
    (
        4,
        'What is the triple-angle formula for cosine?',
        'cos 3x = 4 cos^3 x - 3 cos x'
    ),
    -- Lesson 5: Definite and Improper Integrals (lesson_id = 5)
    (
        5,
        'Evaluate ∫_0^∞ x^2 e^{-x} dx.',
        '2 (Gamma function Γ(3) = 2!)'
    ),
    (
        5,
        'When is ∫_1^∞ 1/(x (ln x)^p) convergent?',
        'Convergent if p > 1'
    ),
    (
        5,
        'State integration by parts formula.',
        '∫ u dv = uv - ∫ v du'
    ),
    (
        5,
        'What is an improper integral?',
        'An integral with infinite limits or integrand singularities'
    ),
    (
        5,
        'How to test convergence for improper integrals?',
        'Compare with known convergent/divergent integrals or use limit comparison'
    ),
    -- Lesson 6: Vectors in Space and Planes (lesson_id = 6)
    (
        6,
        'How to compute the dot product of vectors a and b?',
        'a·b = |a||b|cos θ = Σ a_i b_i'
    ),
    (
        6,
        'What is the cross product useful for?',
        'Find a vector orthogonal to two vectors and compute area of parallelogram'
    ),
    (
        6,
        'Equation of a plane given point r0 and normal n?',
        'n·(r - r0) = 0'
    ),
    (
        6,
        'How to find distance from point to plane?',
        'Use |n·(r0 - r)|/|n| formula'
    ),
    (
        6,
        'How to find intersection line of two planes?',
        'Solve the two plane equations simultaneously to get parametric line'
    ),
    -- Lesson 7: Conic Sections (lesson_id = 7)
    (
        7,
        'Define a conic using focus and directrix.',
        'Set of points with distance ratio to focus/directrix equal to eccentricity e'
    ),
    (
        7,
        'What is eccentricity of a parabola?',
        'e = 1'
    ),
    (
        7,
        'Equation of an ellipse centered at origin (major along x).',
        'x^2/a^2 + y^2/b^2 = 1'
    ),
    (
        7,
        'What property does a parabola have related to reflection?',
        'Reflective property: rays from focus reflect parallel to axis'
    ),
    (
        7,
        'Define hyperbola eccentricity relation.',
        'For hyperbola, e > 1 and relation b^2 = a^2(e^2 - 1)'
    ),
    -- Lesson 8: Inequalities: AM-GM, Cauchy, and Jensen (lesson_id = 8)
    (
        8,
        'State AM-GM inequality for two positives a and b.',
        '(a+b)/2 ≥ √(ab)'
    ),
    (
        8,
        'What does Cauchy-Schwarz inequality state?',
        '(Σ a_i^2)(Σ b_i^2) ≥ (Σ a_i b_i)^2'
    ),
    (
        8,
        'When is equality achieved in AM-GM?',
        'When all variables are equal'
    ),
    (
        8,
        'What is Jensen''s inequality about?',
        'Convex function: f(λx+(1-λ)y) ≤ λf(x)+(1-λ)f(y)'
    ),
    (
        8,
        'For xyz=1 minimize x+y+z (positive vars).',
        'By AM-GM the minimum is 3 when x=y=z=1'
    ),
    -- Lesson 9: Sequences and Power Series: Uniform Convergence (lesson_id = 9)
    (
        9,
        'Define uniform convergence of functions sequence f_n on set A.',
        'f_n → f uniformly if ∀ε∃N s.t. ∀n≥N and ∀x∈A, |f_n(x)-f(x)|<ε'
    ),
    (
        9,
        'State Weierstrass M-test.',
        'If |f_n(x)| ≤ M_n and Σ M_n converges then Σ f_n converges uniformly'
    ),
    (
        9,
        'What is radius of convergence?',
        'Distance from center within which power series converges'
    ),
    (
        9,
        'Does ∑ n^2 x^n have radius of convergence 1?',
        'Yes, by root or ratio test R=1'
    ),
    (
        9,
        'When can you interchange limit and integral?',
        'If convergence is uniform and integrands are continuous (or dominated convergence applies)'
    ),
    -- Lesson 10: Matrices, Determinants and Eigenvalues (lesson_id = 10)
    (
        10,
        'What is the characteristic polynomial of matrix A?',
        'det(A - λI)'
    ),
    (
        10,
        'How to check if a matrix is diagonalizable?',
        'If there are enough linearly independent eigenvectors to form a basis'
    ),
    (
        10,
        'What does determinant tell about invertibility?',
        'Matrix is invertible iff determinant ≠ 0'
    ),
    (
        10,
        'How to compute eigenvalues?',
        'Solve det(A - λI) = 0'
    ),
    (
        10,
        'What is the relationship between trace and eigenvalues?',
        'Trace equals sum of eigenvalues'
    );