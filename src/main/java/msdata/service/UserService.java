package msdata.service;

import msdata.domain.command.UserCommandEntity;
import msdata.domain.query.UserQueryEntity;
import msdata.repository.command.UserCommandRepository;
import msdata.repository.query.UserQueryRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Servicio de Usuarios con patrón CQRS
 *
 * Separa operaciones de lectura (Query) y escritura (Command):
 * - Commands: Usan commandTransactionManager
 * - Queries: Usan queryTransactionManager (read-only)
 *
 * Beneficios:
 * - Escalabilidad: Queries pueden ir a réplica read-only
 * - Rendimiento: Pool separado para lecturas/escrituras
 * - Claridad: Separación explícita de responsabilidades
 */
@Service
public class UserService {

    private final UserCommandRepository commandRepository;
    private final UserQueryRepository queryRepository;

    public UserService(UserCommandRepository commandRepository,
                      UserQueryRepository queryRepository) {
        this.commandRepository = commandRepository;
        this.queryRepository = queryRepository;
    }

    // ════════════════════════════════════════════════════════════
    // COMMANDS (Escrituras)
    // ════════════════════════════════════════════════════════════

    /**
     * Crear nuevo usuario
     *
     * @Transactional con commandTransactionManager
     * - Garantiza ACID
     * - Rollback automático si hay error
     */
    @Transactional("commandTransactionManager")
    public UserCommandEntity createUser(String name, String email) {
        // Validación: Email único
        if (commandRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists: " + email);
        }

        UserCommandEntity user = new UserCommandEntity(name, email);
        return commandRepository.save(user);
    }

    /**
     * Actualizar nombre de usuario
     *
     * @Transactional con commandTransactionManager
     * - Usa optimistic locking (@Version)
     * - Detecta modificaciones concurrentes
     */
    @Transactional("commandTransactionManager")
    public UserCommandEntity updateUserName(Long id, String newName) {
        UserCommandEntity user = commandRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + id));

        user.update(newName);
        return commandRepository.save(user);
    }

    /**
     * Eliminar usuario
     *
     * @Transactional con commandTransactionManager
     */
    @Transactional("commandTransactionManager")
    public void deleteUser(Long id) {
        if (!commandRepository.existsById(id)) {
            throw new IllegalArgumentException("User not found: " + id);
        }
        commandRepository.deleteById(id);
    }

    // ════════════════════════════════════════════════════════════
    // QUERIES (Lecturas)
    // ════════════════════════════════════════════════════════════

    /**
     * Buscar usuario por ID
     *
     * @Transactional con queryTransactionManager (readOnly = true)
     * - Optimizado para lectura
     * - No hay overhead de gestión transaccional pesada
     */
    @Transactional(value = "queryTransactionManager", readOnly = true)
    public Optional<UserQueryEntity> findUserById(Long id) {
        return queryRepository.findById(id);
    }

    /**
     * Buscar usuario por email
     */
    @Transactional(value = "queryTransactionManager", readOnly = true)
    public Optional<UserQueryEntity> findUserByEmail(String email) {
        return queryRepository.findByEmail(email);
    }

    /**
     * Buscar usuarios por nombre (búsqueda parcial)
     */
    @Transactional(value = "queryTransactionManager", readOnly = true)
    public List<UserQueryEntity> searchUsersByName(String name) {
        return queryRepository.findByNameContaining(name);
    }

    /**
     * Listar todos los usuarios paginados
     * Recomendado para listados en UI
     */
    @Transactional(value = "queryTransactionManager", readOnly = true)
    public Page<UserQueryEntity> listUsers(Pageable pageable) {
        return queryRepository.findAll(pageable);
    }

    /**
     * Obtener usuarios recientes
     */
    @Transactional(value = "queryTransactionManager", readOnly = true)
    public List<UserQueryEntity> getRecentUsers(int limit) {
        Pageable pageable = Pageable.ofSize(limit);
        return queryRepository.findRecentUsers(pageable);
    }

    /**
     * Contar total de usuarios
     */
    @Transactional(value = "queryTransactionManager", readOnly = true)
    public long countUsers() {
        return queryRepository.countAllUsers();
    }
}
