DROP DATABASE IF EXISTS teeth_clinic_db;
CREATE DATABASE teeth_clinic_db CHARACTER SET utf8mb4;
USE teeth_clinic_db;

-- 1. Пациенты
CREATE TABLE patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL
);

-- 2. Врачи
CREATE TABLE doctors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100) NOT NULL
);

-- 3. Услуги (каталог/прайс)
CREATE TABLE services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- 4. Приёмы (расписание для админа, поле result — для врача)
CREATE TABLE appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_time DATETIME NOT NULL,
    status VARCHAR(30) DEFAULT 'Запланирован', -- Запланирован, Завершен, Отменен
    result TEXT NULL,                         -- Фиксация результатов врачом
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
);

-- 5. Выполненные процедуры (услуги, оказанные в рамках конкретного приёма)
CREATE TABLE appointment_services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    service_id INT NOT NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
);

-- 6. Пользователи с ролями
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(30) NOT NULL,      -- 'Администратор' или 'Врач'
    doctor_id INT NULL,             -- Если 'Врач', указывается его ID из таблицы doctors
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE SET NULL
);

-- Тестовые данные:
INSERT INTO patients (full_name, phone) VALUES
('Иванов Иван Иванович', '+79991112233'),
('Петрова Анна Сергеевна', '+79992223344');

INSERT INTO doctors (full_name, specialty) VALUES
('Смирнов Алексей Павлович', 'Стоматолог-терапевт'),
('Кузнецова Ольга Дмитриевна', 'Стоматолог-хирург');

INSERT INTO users (username, password, role, doctor_id) VALUES
('admin', 'admin123', 'Администратор', NULL),
('doctor1', 'doc123', 'Врач', 1);

INSERT INTO services (name, price) VALUES
('Первичный осмотр и консультация', 500.00),
('Лечение кариеса и пломбирование', 3500.00),
('Удаление зуба простое', 2000.00);

-- Запись на приём (для роли Врач / Администратор)
INSERT INTO appointments (patient_id, doctor_id, appointment_time, status, result) VALUES
(1, 1, '2026-11-01 10:00:00', 'Завершен', 'Кариес устранён, установлена световая пломба.'),
(2, 2, '2026-11-02 12:30:00', 'Запланирован', NULL);

-- Выполненные процедуры для первого приёма
INSERT INTO appointment_services (appointment_id, service_id) VALUES
(1, 1),
(1, 2);