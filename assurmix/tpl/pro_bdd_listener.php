<?php
// Assurmix DEV -> pro/secure/script/bdd_listener.php (API interne BDD).
require_once "../php/config.php";
require_once "./bdd_reader.php";

function getAuthorizationHeader()
{
    $headers = null;
    if (isset($_SERVER['Authorization'])) {
        $headers = trim($_SERVER["Authorization"]);
    } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers = trim($_SERVER["HTTP_AUTHORIZATION"]);
    } elseif (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        $requestHeaders = array_combine(array_map('ucwords', array_keys($requestHeaders)), array_values($requestHeaders));
        if (isset($requestHeaders['Authorization'])) {
            $headers = trim($requestHeaders['Authorization']);
        }
    }
    return $headers;
}

function getBearerToken()
{
    $headers = getAuthorizationHeader();
    if (!empty($headers)) {
        if (preg_match('/Bearer\s(\S+)/', $headers, $matches)) {
            return $matches[1];
        }
    }
    return null;
}

if (getBearerToken() != API_BDD_TOKEN) {
    header('HTTP/1.0 401 Unauthorized');
    echo utf8_decode('<center><strong>Attention vous n\'etes pas autorise a entrer</strong></center>');
    exit;
}

define("DB_SERVER", "portomix_data");
define("DB_USER",   "${ASSUR_DB_USER}");
define("DB_PASS",   "${ASSUR_DB_PASS}");
define("DB_NAME",   "assurmix");

$link = mysqli_connect(DB_SERVER, DB_USER, DB_PASS, DB_NAME);
mysqli_set_charset($link, "utf8");
$data_manager_api = new BddReader($link);

$post = (object) json_decode(file_get_contents('php://input'), true);
if (!isset($post->action)) {
    $retour = array(["return" => "Erreur dans appel API", "value" => "il manque le parametre action"]);
    echo json_encode($retour);
    exit;
}

switch ($post->action) {
    case "say_hello":
        $data = $data_manager_api->say_hello();
        break;
    case "get_user_by_id":
        $data = $data_manager_api->get_user_by_id($post->id);
        break;
    case "get_groups":
        $data = $data_manager_api->get_groups();
        break;
    default:
        $data = array(["return" => "Erreur dans appel API", "value" => "Le parametre action ne correspond pas a une requete"]);
}

echo json_encode($data);
