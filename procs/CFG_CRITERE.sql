SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_CRITERE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_cri_idcritere : Identifiant
--			  @v_cri_libelle : Libellé
--			  @v_cri_memo : Commentaire
--			  @v_cri_famille : Famille
--			  @v_cri_type : Type
--			  @v_cri_implementation : Implémentation
--			  @v_cri_procedure : Procédure
--			  @v_cri_parametre : Paramètres
--			  @v_cri_donnee : Type de données
--			  @v_lan_id : Identifiant langue
-- ParamÞtre de sorties	: @v_retour : Code de retour
--			  @v_tra_idlibelle : Identifiant traduction libellé
--			  @v_tra_idmemo : Identifiant traduction mémo
-- Descriptif		: Gestion des critères
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_CRITERE]
	@v_action smallint,
	@v_cri_idcritere int,
	@v_cri_libelle varchar(8000),
	@v_cri_memo varchar(8000),
	@v_cri_famille tinyint,
	@v_cri_type bit,
	@v_cri_implementation bit,
	@v_cri_procedure varchar(32),
	@v_cri_parametre varchar(3500),
	@v_cri_donnee tinyint,
	@v_lan_id varchar(3),
	@v_tra_idlibelle int out,
	@v_tra_idmemo int out,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int,
	@v_criidcritere int,
	@v_criidtraductionlibelle int,
	@v_criidtraductionmemo int

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM CRITERE, LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = CRI_IDTRADUCTIONLIBELLE AND LIB_LIBELLE = @v_cri_libelle)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_cri_libelle, @v_tra_idlibelle out
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_cri_memo, @v_tra_idmemo out
				IF @v_error = 0
				BEGIN
					INSERT INTO CRITERE (CRI_IDCRITERE, CRI_IDTYPE, CRI_IDTRADUCTIONLIBELLE, CRI_IDTRADUCTIONMEMO, CRI_FAMILLE, CRI_SYSTEME,
						CRI_IMPLEMENTATION, CRI_PROCEDURE, CRI_PARAMETRE, CRI_DONNEE) SELECT (SELECT CASE SIGN(MIN(CRI_IDCRITERE)) WHEN -1 THEN MIN(CRI_IDCRITERE) - 1 ELSE -1 END FROM CRITERE),
						@v_cri_type, @v_tra_idlibelle, @v_tra_idmemo, @v_cri_famille, 0, @v_cri_implementation, @v_cri_procedure, @v_cri_parametre, @v_cri_donnee
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
		END
		ELSE
			SET @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM CRITERE, LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = CRI_IDTRADUCTIONLIBELLE AND LIB_LIBELLE = @v_cri_libelle AND CRI_IDCRITERE <> @v_cri_idcritere)
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_cri_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_idlibelle
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_cri_memo WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_idmemo
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE CRITERE SET CRI_IDTYPE = @v_cri_type, CRI_FAMILLE = @v_cri_famille, CRI_IMPLEMENTATION = @v_cri_implementation,
						CRI_PROCEDURE = @v_cri_procedure, CRI_PARAMETRE = @v_cri_parametre, CRI_DONNEE = @v_cri_donnee WHERE CRI_IDCRITERE = @v_cri_idcritere
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
		END
		ELSE
			SET @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM CONDITION WHERE CDT_IDCRITERE = @v_cri_idcritere)
			UNION (SELECT 1 FROM TRI WHERE TRI_IDCRITERE = @v_cri_idcritere))
		BEGIN
			DELETE CRITERE_ZONE WHERE CRZ_IDCRITERE = @v_cri_idcritere
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE CRITERE_MISSION WHERE CRM_IDCRITERE = @v_cri_idcritere
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE CRITERE WHERE CRI_IDCRITERE = @v_cri_idcritere
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_idlibelle out
						IF @v_error = 0
						BEGIN
							EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_idmemo out
							IF @v_error = 0
								SET @v_retour = 0
						END
					END
				END
			END
		END
		ELSE
			SET @v_retour = 114
	END
	ELSE IF @v_action = 3
	BEGIN
		DECLARE c_critere CURSOR LOCAL FOR SELECT CRI_IDCRITERE, CRI_IDTRADUCTIONLIBELLE, CRI_IDTRADUCTIONMEMO FROM CRITERE WHERE CRI_SYSTEME = 0 FOR UPDATE
		OPEN c_critere
		FETCH NEXT FROM c_critere INTO @v_criidcritere, @v_criidtraductionlibelle, @v_criidtraductionmemo
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			IF NOT EXISTS ((SELECT 1 FROM CONDITION WHERE CDT_IDCRITERE = @v_criidcritere)
				UNION (SELECT 1 FROM TRI WHERE TRI_IDCRITERE = @v_criidcritere))
			BEGIN
				DELETE CRITERE_ZONE WHERE CRZ_IDCRITERE = @v_cri_idcritere
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE CRITERE_MISSION WHERE CRM_IDCRITERE = @v_criidcritere
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE CRITERE WHERE CURRENT OF c_critere
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_criidtraductionlibelle out
							IF @v_error = 0
								EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_criidtraductionmemo out
						END
					END
				END
			END
			FETCH NEXT FROM c_critere INTO @v_criidcritere, @v_criidtraductionlibelle, @v_criidtraductionmemo
		END
		CLOSE c_critere
		DEALLOCATE c_critere
		SET @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

