SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_ABONNE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_abo_id : Identifiant abonné
--			  @v_abo_implementation : Implémentation
--			  @v_mes_id : Identifiant message
--			  @v_abn_procedure : Procédure stockée
--			  @v_abn_timeout : Délai
--			  @v_ama_parametre : Paramètre
--			  @v_att_id : Attribut
--			  @v_lib_libelle : Libellé
--			  @v_lan_id : Identifiant langue
-- Paramètre de sortie	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des abonnés
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_ABONNE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_abo_id int out,
	@v_abo_implementation bit,
	@v_mes_id int,
	@v_abn_procedure varchar(32),
	@v_abn_timeout int,
	@v_ama_parametre varchar(32),
	@v_att_id smallint,
	@v_lib_libelle varchar(8000),
	@v_lan_id varchar(3),
	@v_tra_id int out,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			SELECT @v_abo_id = CASE SIGN(MIN(ABO_ID)) WHEN -1 THEN MIN(ABO_ID) - 1 ELSE -1 END FROM ABONNE
			INSERT INTO ABONNE (ABO_ID, ABO_ON, ABO_SYSTEME, ABO_IDTRADUCTION, ABO_IMPLEMENTATION)
				VALUES (@v_abo_id, 0, 0, @v_tra_id, @v_abo_implementation)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			INSERT INTO ABONNEMENT (ABN_ABONNE, ABN_MESSAGE, ABN_TIMEOUT) VALUES (@v_abo_id, @v_mes_id, 30)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			DELETE ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id AND AMA_MESSAGE = @v_mes_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ABONNEMENT WHERE ABN_ABONNE = @v_abo_id AND ABN_MESSAGE = @v_mes_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			DELETE ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ABONNEMENT WHERE ABN_ABONNE = @v_abo_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					INSERT INTO ABONNEMENT (ABN_ABONNE, ABN_MESSAGE, ABN_TIMEOUT) SELECT @v_abo_id, MES_ID, 30 FROM MESSAGE WHERE MES_RECEPTION = 1
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			DELETE ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ABONNEMENT WHERE ABN_ABONNE = @v_abo_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 4
		BEGIN
			UPDATE ABONNE SET ABO_IMPLEMENTATION = @v_abo_implementation WHERE ABO_ID = @v_abo_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 5
		BEGIN
			UPDATE ABONNEMENT SET ABN_PROCEDURE = @v_abn_procedure, ABN_TIMEOUT = @v_abn_timeout WHERE ABN_ABONNE = @v_abo_id AND ABN_MESSAGE = @v_mes_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id AND AMA_MESSAGE = @v_mes_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction IN (6, 7)
		BEGIN
			IF @v_ssaction = 6
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id AND AMA_MESSAGE = @v_mes_id
					AND AMA_PARAMETRE = @v_ama_parametre)
					INSERT INTO ASSOCIATION_MEMBRE_ABONNEMENT (AMA_ABONNE, AMA_MESSAGE, AMA_PARAMETRE, AMA_ATTRIBUT)
						VALUES (@v_abo_id, @v_mes_id, @v_ama_parametre, @v_att_id)
				ELSE
					UPDATE ASSOCIATION_MEMBRE_ABONNEMENT SET AMA_ATTRIBUT = @v_att_id WHERE AMA_ABONNE = @v_abo_id AND AMA_MESSAGE = @v_mes_id
						AND AMA_PARAMETRE = @v_ama_parametre
				SELECT @v_error = @@ERROR
			END
			ELSE IF @v_ssaction = 7
			BEGIN
				DELETE ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id AND AMA_MESSAGE = @v_mes_id
					AND AMA_PARAMETRE = @v_ama_parametre
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				DELETE ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id AND AMA_MESSAGE = @v_mes_id
					AND AMA_PARAMETRE NOT IN (SELECT PARAMETER_NAME FROM INFORMATION_SCHEMA.PARAMETERS
					WHERE SPECIFIC_NAME = PARSENAME(@v_abn_procedure, 1))
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ASSOCIATION_MEMBRE_ABONNEMENT WHERE AMA_ABONNE = @v_abo_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE ABONNEMENT WHERE ABN_ABONNE = @v_abo_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ABONNE WHERE ABO_ID = @v_abo_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

