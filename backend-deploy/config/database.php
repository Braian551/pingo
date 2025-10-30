<?php
// backend/config/database.php

class Database {
    private $host;
    private $db_name;
    private $username;
    private $password;
    public $conn;

    public function __construct() {
        // Railway environment variables
        $this->host = getenv('MYSQLHOST') ?: getenv('DATABASE_HOST') ?: 'localhost';
        $this->db_name = getenv('MYSQLDATABASE') ?: getenv('DATABASE_NAME') ?: 'pingo';
        $this->username = getenv('MYSQLUSER') ?: getenv('DATABASE_USER') ?: 'root';
        $this->password = getenv('MYSQLPASSWORD') ?: getenv('DATABASE_PASSWORD') ?: 'root';
    }

    public function getConnection() {
        $this->conn = null;

        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8",
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        } catch(PDOException $exception) {
            throw new Exception("Error de conexión: " . $exception->getMessage());
        }

        return $this->conn;
    }
}
?>