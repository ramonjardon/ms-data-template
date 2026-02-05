package msdata.domain.command;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity para Commands (Escrituras)
 *
 * Representa un usuario en el sistema para operaciones de escritura.
 * Esta entity se usa SOLO para INSERT/UPDATE/DELETE.
 *
 * Para lecturas, usar msdata.domain.query.UserQueryEntity
 */
@Entity
@Table(name = "users")
public class UserCommandEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, unique = true, length = 255)
    private String email;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Version
    private Long version;  // Optimistic locking

    // Constructor vacío requerido por JPA
    protected UserCommandEntity() {
    }

    // Constructor para nuevos usuarios
    public UserCommandEntity(String name, String email) {
        this.name = name;
        this.email = email;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    // Método de actualización
    public void update(String name) {
        this.name = name;
        this.updatedAt = LocalDateTime.now();
    }

    // Getters
    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public Long getVersion() {
        return version;
    }
}
