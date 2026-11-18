DROP DATABASE IF EXISTS labday;

CREATE DATABASE agendamento_labs
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE labday;

CREATE TABLE laboratorios (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(100) NOT NULL,
  tipo       ENUM('Informática', 'Ciências', 'Física', 'Engenharia') NOT NULL,
  capacidade INT NOT NULL,
  campus     ENUM('Paulista', 'Vila Olímpia', 'Mooca') NOT NULL,
  andar      INT NOT NULL,
  sala       VARCHAR(10) NOT NULL,
  status     VARCHAR(20) NOT NULL DEFAULT 'ATIVO',

  CONSTRAINT uq_sala_campus UNIQUE (campus, sala),

  CONSTRAINT chk_andar CHECK (
       (campus = 'Mooca'        AND andar BETWEEN 1 AND 7)
    OR (campus = 'Paulista'     AND andar BETWEEN 1 AND 14)
    OR (campus = 'Vila Olímpia' AND andar BETWEEN 1 AND 10)
  )
);

CREATE TABLE usuarios (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(100) NOT NULL,
  ra         VARCHAR(20)  NOT NULL UNIQUE,
  email      VARCHAR(100) NOT NULL UNIQUE,
  perfil     VARCHAR(20)  NOT NULL,
  senha_hash VARCHAR(255) NOT NULL
);

CREATE TABLE disciplinas (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  nome             VARCHAR(100) NOT NULL,
  curso            VARCHAR(100) NOT NULL,
  tipo_laboratorio ENUM('Informática', 'Ciências', 'Física', 'Engenharia') NOT NULL,
  campus           ENUM('Paulista', 'Vila Olímpia', 'Mooca') NOT NULL
);

CREATE TABLE agendamentos (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario       INT  NOT NULL,
  id_laboratorio   INT  NOT NULL,
  id_disciplina    INT  NOT NULL,
  data_agendamento DATE NOT NULL,
  hora_inicio      TIME NOT NULL,
  hora_fim         TIME NOT NULL,

  FOREIGN KEY (id_usuario)     REFERENCES usuarios(id),
  FOREIGN KEY (id_laboratorio) REFERENCES laboratorios(id),
  FOREIGN KEY (id_disciplina)  REFERENCES disciplinas(id),

  CONSTRAINT chk_horas CHECK (hora_fim > hora_inicio)
);

CREATE TABLE limites_uso (
  perfil         VARCHAR(20) PRIMARY KEY,
  limite_minutos INT NOT NULL
);

INSERT INTO laboratorios (nome, tipo, capacidade, campus, andar, sala) VALUES
  ('Laboratório de Ciências (Química e Biologia)', 'Ciências',    30, 'Mooca',        2,  '15'),
  ('Laboratório de Informática 1',                 'Informática', 40, 'Mooca',        3,  '28'),
  ('Laboratório de Física',                        'Física',      28, 'Mooca',        5,  '43'),
  ('Laboratório de Engenharia',                    'Engenharia',  25, 'Mooca',        7,  '61'),
  ('Laboratório de Informática 1',                 'Informática', 45, 'Paulista',     2,  '9'),
  ('Laboratório de Informática 2',                 'Informática', 40, 'Paulista',     4,  '34'),
  ('Laboratório de Ciências (Química e Biologia)', 'Ciências',    30, 'Paulista',     7,  '72'),
  ('Laboratório de Engenharia',                    'Engenharia',  25, 'Paulista',     10, '104'),
  ('Laboratório de Física',                        'Física',      28, 'Paulista',     13, '131'),
  ('Laboratório de Informática 1',                 'Informática', 40, 'Vila Olímpia', 1,  '3'),
  ('Laboratório de Informática 2',                 'Informática', 35, 'Vila Olímpia', 3,  '22'),
  ('Laboratório de Ciências (Química e Biologia)', 'Ciências',    30, 'Vila Olímpia', 4,  '48'),
  ('Laboratório de Física',                        'Física',      28, 'Vila Olímpia', 6,  '65'),
  ('Laboratório de Engenharia 1',                  'Engenharia',  25, 'Vila Olímpia', 8,  '87'),
  ('Laboratório de Engenharia 2',                  'Engenharia',  25, 'Vila Olímpia', 10, '102');

INSERT INTO limites_uso (perfil, limite_minutos) VALUES
  ('aluno',     120),
  ('professor', 300);

DELIMITER $$

CREATE TRIGGER trg_conflito_insert
BEFORE INSERT ON agendamentos
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM agendamentos
    WHERE id_laboratorio   = NEW.id_laboratorio
      AND data_agendamento = NEW.data_agendamento
      AND hora_inicio      < NEW.hora_fim
      AND hora_fim         > NEW.hora_inicio
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Conflito de horario: laboratorio ja reservado nesse periodo';
  END IF;
END$$

CREATE TRIGGER trg_conflito_update
BEFORE UPDATE ON agendamentos
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM agendamentos
    WHERE id_laboratorio   = NEW.id_laboratorio
      AND data_agendamento = NEW.data_agendamento
      AND hora_inicio      < NEW.hora_fim
      AND hora_fim         > NEW.hora_inicio
      AND id               <> NEW.id
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Conflito de horario: laboratorio ja reservado nesse periodo';
  END IF;
END$$

DELIMITER ; 