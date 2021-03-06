SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_PORTE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_por_id : Identifiant AGV
--			  @v_sas_id : Identifiant sas
--			  @v_por_interface : Interface
--			  @v_por_variable_automate_commande : Variable automate commande
--			  @v_por_entree_sortie_commande : Entrée/sortie logique commande
--			  @v_por_valeur_ouverture : Valeur "Ouverture"
--			  @v_por_variable_automate_etat : Variable automate état
--			  @v_por_entree_sortie_etat : Entrée/sortie logique état
--			  @v_por_valeur_ouvert : Valeur "Ouvert"
--			  @v_por_menu_contextuel : Menu contextuel
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des portes
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_PORTE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_por_id int,
	@v_sas_id int out,
	@v_por_interface int,
	@v_por_variable_automate_commande int,
	@v_por_entree_sortie_commande int,
	@v_por_valeur_ouverture bit,
	@v_por_variable_automate_etat int,
	@v_por_entree_sortie_etat int,
	@v_por_valeur_ouvert bit,
	@v_por_menu_contextuel int,
	@v_lan_id varchar(3),
	@v_tra_id int out,
	@v_lib_libelle varchar(8000),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int

-- Déclaration des constantes de menu contextuel
DECLARE
	@MENU_PORTE int

-- Définition des constantes
	SET @v_retour = 113
	SET @v_status = 0
	SET @v_error = 0
	SET @MENU_PORTE = 4
	
	BEGIN TRAN
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM PORTE, LIBELLE WHERE LIB_TRADUCTION = POR_TRADUCTION AND LIB_LIBELLE = @v_lib_libelle)
			AND NOT EXISTS (SELECT 1 FROM PORTE WHERE POR_ID = @v_por_id)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO PORTE (POR_ID, POR_TRADUCTION, POR_SERVICE, POR_MENU_CONTEXTUEL)
					VALUES (@v_por_id, @v_tra_id, 0, @MENU_PORTE)
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
		ELSE
			SET @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM PORTE, LIBELLE WHERE LIB_TRADUCTION = POR_TRADUCTION AND LIB_LIBELLE = @v_lib_libelle)
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
			ELSE
				SET @v_retour = 117
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			UPDATE PORTE SET POR_INTERFACE = @v_por_interface, POR_VARIABLE_AUTOMATE_COMMANDE = @v_por_variable_automate_commande, POR_ENTREE_SORTIE_COMMANDE = @v_por_entree_sortie_commande,
				POR_VALEUR_OUVERTURE = @v_por_valeur_ouverture, POR_VARIABLE_AUTOMATE_ETAT = @v_por_variable_automate_etat, POR_ENTREE_SORTIE_etat = @v_por_entree_sortie_etat,
				POR_VALEUR_OUVERT = @v_por_valeur_ouvert WHERE POR_ID = @v_por_id
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_PORTE_SAS WHERE APS_PORTE = @v_por_id)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM SAS WHERE SAS_ID = @v_sas_id)
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM SAS, LIBELLE WHERE LIB_TRADUCTION = SAS_TRADUCTION AND LIB_LIBELLE = @v_lib_libelle)
					BEGIN
						EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_lib_libelle, @v_tra_id out
						IF @v_error = 0
						BEGIN
							INSERT INTO SAS (SAS_TRADUCTION) VALUES (@v_tra_id)
							SET @v_error = @@ERROR
							IF @v_error = 0
								SET @v_sas_id = SCOPE_IDENTITY()
						END
					END
					ELSE
						SET @v_retour = 117
				END
				IF @v_error = 0
				BEGIN
					INSERT INTO ASSOCIATION_PORTE_SAS (APS_SAS, APS_PORTE) VALUES (@v_sas_id, @v_por_id)
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
			ELSE
				SET @v_retour = 117
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			SELECT @v_tra_id = SAS_TRADUCTION FROM SAS WHERE SAS_ID = @v_sas_id
			DELETE ASSOCIATION_PORTE_SAS WHERE APS_SAS = @v_sas_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE SAS WHERE SAS_ID = @v_sas_id
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_tra_id out
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
		END		
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ASSOCIATION_PORTE_SAS WHERE APS_PORTE = @v_por_id
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE SAS WHERE EXISTS (SELECT 1 FROM SAS INNER JOIN ASSOCIATION_PORTE_SAS ON APS_SAS = SAS_ID HAVING COUNT(*) < 2)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_INFO_AGV_PORTE WHERE AIP_PORTE = @v_por_id
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE PORTE WHERE POR_ID = @v_por_id
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
						IF @v_error = 0
							SET @v_retour = 0
					END
				END
			END
		END
	END
	IF ((@v_error = 0) AND (@v_retour = 0))
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_error

