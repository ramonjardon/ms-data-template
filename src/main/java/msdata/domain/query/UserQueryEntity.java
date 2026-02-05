package msdata.domain.query;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity para Queries (Lecturas)
 *
 * Representa un usuario en el sistema para operaciones de lectura.
 * Esta entity se usa SOLO para SELECT.
 * Es inmutable - no se modifica desde código.
 *
 * Para escrituras, usar msdata.domain.command.UserCommandEntity
 */
@Entity
@Table(name = "users")
public class UserQueryEntity {

    @Id
    private Long id;

    @Column(name = "name")
    private String name;

    @Column(name = "email")
    private String email;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Constructor vacío requerido por JPA
    protected UserQueryEntity() {
    }

    // Solo getters - Inmutable
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
}
