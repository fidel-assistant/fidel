"""Profils patient, maladies, traitements, sync aidant."""

from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.catalog import MaladieConfig, ProtocoleTraitement
    from app.models.medication import Medicament
    from app.models.sante import Constante
    from app.models.user import User


class Patient(Base):
    __tablename__ = "patients"

    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    localisation: Mapped[str | None] = mapped_column(String(255), nullable=True)
    nom_complet: Mapped[str | None] = mapped_column(String(255), nullable=True)
    date_naissance: Mapped[date | None] = mapped_column(Date, nullable=True)
    sexe: Mapped[str | None] = mapped_column(String(32), nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    notifications_accordees: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    batterie_exemptee: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    notifications_discretes: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    groupe_sanguin: Mapped[str | None] = mapped_column(String(8), nullable=True)
    rhesus: Mapped[str | None] = mapped_column(String(4), nullable=True)
    electrophorese: Mapped[str | None] = mapped_column(String(16), nullable=True)
    taille_cm: Mapped[int | None] = mapped_column(Integer, nullable=True)
    groupe_sanguin_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    rhesus_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    electrophorese_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    taille_cm_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped[User] = relationship(back_populates="patient")
    traitements: Mapped[list[PatientTraitement]] = relationship(back_populates="patient")
    sync_codes: Mapped[list[SyncCode]] = relationship(back_populates="patient")
    aidants: Mapped[list[PatientAidant]] = relationship(back_populates="patient")
    contacts_urgence: Mapped[list[ContactUrgence]] = relationship(
        back_populates="patient", cascade="all, delete-orphan"
    )
    check_ins: Mapped[list[CheckIn]] = relationship(
        back_populates="patient", cascade="all, delete-orphan"
    )
    sos_alertes: Mapped[list[SosAlerte]] = relationship(
        back_populates="patient", cascade="all, delete-orphan"
    )
    constantes: Mapped[list[Constante]] = relationship(
        "Constante", back_populates="patient", cascade="all, delete-orphan"
    )
    voix_rappel: Mapped[VoixRappel | None] = relationship(
        back_populates="patient", uselist=False, cascade="all, delete-orphan"
    )


class Maladie(Base):
    __tablename__ = "maladies"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    code: Mapped[str] = mapped_column(String(64), nullable=False, unique=True, index=True)
    nom: Mapped[str] = mapped_column(String(128), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    config: Mapped[MaladieConfig | None] = relationship(
        "MaladieConfig", back_populates="maladie", uselist=False
    )
    protocoles: Mapped[list[ProtocoleTraitement]] = relationship(
        "ProtocoleTraitement", back_populates="maladie"
    )
    patient_traitements: Mapped[list[PatientTraitement]] = relationship(back_populates="maladie")


class PatientTraitement(Base):
    __tablename__ = "patient_traitements"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    maladie_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("maladies.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    protocole_id: Mapped[UUID | None] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("protocoles_traitement.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    phase: Mapped[str] = mapped_column(String(32), nullable=False)
    en_traitement: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true")
    )
    date_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    date_fin_prevue: Mapped[date | None] = mapped_column(Date, nullable=True)
    maladie_libelle: Mapped[str | None] = mapped_column(String(255), nullable=True)
    lieu_suivi: Mapped[str | None] = mapped_column(String(255), nullable=True)
    statut: Mapped[str] = mapped_column(
        String(32), nullable=False, server_default="actif", index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="traitements")
    maladie: Mapped[Maladie] = relationship(back_populates="patient_traitements")
    protocole: Mapped[ProtocoleTraitement | None] = relationship(
        "ProtocoleTraitement", back_populates="patient_traitements"
    )
    attributs: Mapped[list[PatientTraitementAttribut]] = relationship(
        back_populates="traitement", cascade="all, delete-orphan"
    )
    medicaments: Mapped[list[Medicament]] = relationship("Medicament", back_populates="traitement")


class PatientTraitementAttribut(Base):
    """Réponses spécifiques par maladie (EAV) — ex. type_diabete, dot_supervise."""

    __tablename__ = "patient_traitement_attributs"
    __table_args__ = (
        UniqueConstraint("patient_traitement_id", "code", name="uq_traitement_attribut_code"),
    )

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_traitement_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patient_traitements.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    code: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    valeur: Mapped[dict] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    traitement: Mapped[PatientTraitement] = relationship(back_populates="attributs")


class PatientAidant(Base):
    __tablename__ = "patient_aidant"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    aidant_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    statut: Mapped[str] = mapped_column(String(32), nullable=False, server_default="actif")
    niveau_permission: Mapped[dict] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text('\'{"observance": true, "constantes": false}\'::jsonb'),
    )
    notification_prefs: Mapped[dict] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'{}'"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    patient: Mapped[Patient] = relationship(back_populates="aidants")
    aidant: Mapped[User] = relationship(
        back_populates="aidant_relations",
        foreign_keys=[aidant_id],
    )


class SyncCode(Base):
    __tablename__ = "sync_codes"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    code: Mapped[str] = mapped_column(String(16), nullable=False, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="sync_codes")


class ContactUrgence(Base):
    __tablename__ = "contacts_urgence"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    nom: Mapped[str] = mapped_column(String(255), nullable=False)
    telephone: Mapped[str] = mapped_column(String(32), nullable=False)
    relation: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="contacts_urgence")


class CheckIn(Base):
    __tablename__ = "check_ins"
    __table_args__ = (UniqueConstraint("patient_id", "date", name="uq_check_ins_patient_date"),)

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    statut: Mapped[str] = mapped_column(String(32), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="check_ins")


class SosAlerte(Base):
    __tablename__ = "sos_alertes"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    statut: Mapped[str] = mapped_column(
        String(32), nullable=False, server_default="en_attente", index=True
    )
    annulable_jusqu_a: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    envoye_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    annule_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    acked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    acked_by_aidant_id: Mapped[UUID | None] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="sos_alertes")


class VoixRappel(Base):
    __tablename__ = "voix_rappels"
    __table_args__ = (UniqueConstraint("patient_id", name="uq_voix_rappels_patient"),)

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    type: Mapped[str] = mapped_column(String(32), nullable=False, server_default="systeme")
    # Chemin relatif sous MEDIA_ROOT (ex: voix_rappel/<patient_id>/<uuid>.m4a)
    fichier_audio_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    enregistree_par: Mapped[UUID | None] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="voix_rappel")
