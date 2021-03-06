SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_LEGENDE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_leg_id : Identifiant
--			  @v_leg_categorie : Categorie
--			  @v_acl_contenu : Contenu
--			  @v_acl_ordre : Ordre
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des légéndes
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_LEGENDE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_leg_id int,
	@v_leg_categorie tinyint,
	@v_acl_contenu int,
	@v_acl_ordre tinyint,
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

DECLARE
	@v_error smallint,
	@v_old_acl_ordre tinyint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
		IF @v_error = 0
		BEGIN
			INSERT INTO LEGENDE (LEG_ID, LEG_CATEGORIE, LEG_TRADUCTION, LEG_SYSTEME)
				SELECT (SELECT CASE SIGN(MIN(LEG_ID)) WHEN -1 THEN MIN(LEG_ID) - 1 ELSE -1 END FROM LEGENDE), @v_leg_categorie, @v_tra_id, 0
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_CONTENU_LEGENDE WHERE ACL_LEGENDE = @v_leg_id AND ACL_CONTENU = @v_acl_contenu)
			BEGIN
				IF @v_acl_contenu IN (9, 31) AND EXISTS (SELECT 1 FROM ASSOCIATION_CONTENU_LEGENDE WHERE ACL_LEGENDE = @v_leg_id AND ((@v_acl_contenu = 9 AND ACL_CONTENU = 31) OR (@v_acl_contenu = 31 AND ACL_CONTENU = 9)))
				BEGIN
					UPDATE ASSOCIATION_CONTENU_LEGENDE SET ACL_CONTENU = @v_acl_contenu
						WHERE ACL_LEGENDE = @v_leg_id AND ACL_CONTENU = CASE @v_acl_contenu WHEN 9 THEN 31 ELSE 9 END
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
				ELSE
				BEGIN
					INSERT INTO ASSOCIATION_CONTENU_LEGENDE (ACL_LEGENDE, ACL_CONTENU, ACL_ORDRE)
						SELECT @v_leg_id, @v_acl_contenu, ISNULL(MAX(ACL_ORDRE), 0) + 1 FROM ASSOCIATION_CONTENU_LEGENDE WHERE ACL_LEGENDE = @v_leg_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			SELECT @v_old_acl_ordre = ACL_ORDRE FROM ASSOCIATION_CONTENU_LEGENDE WHERE ACL_LEGENDE = @v_leg_id AND ACL_CONTENU = @v_acl_contenu
			IF @v_acl_ordre < @v_old_acl_ordre
			BEGIN
				UPDATE ASSOCIATION_CONTENU_LEGENDE SET ACL_ORDRE = ACL_ORDRE + 1
					WHERE ACL_LEGENDE = @v_leg_id AND ACL_ORDRE >= @v_acl_ordre
					AND ACL_ORDRE < @v_old_acl_ordre AND ACL_CONTENU <> @v_acl_contenu
				SELECT @v_error = @@ERROR
			END
			ELSE IF @v_acl_ordre > @v_old_acl_ordre
			BEGIN
				UPDATE ASSOCIATION_CONTENU_LEGENDE SET ACL_ORDRE = ACL_ORDRE - 1
					WHERE ACL_LEGENDE = @v_leg_id AND ACL_ORDRE > @v_old_acl_ordre
					AND ACL_ORDRE <= @v_acl_ordre AND ACL_CONTENU <> @v_acl_contenu
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				UPDATE ASSOCIATION_CONTENU_LEGENDE SET ACL_ORDRE = @v_acl_ordre
					WHERE ACL_LEGENDE = @v_leg_id AND ACL_CONTENU = @v_acl_contenu
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			DELETE ASSOCIATION_CONTENU_LEGENDE WHERE ACL_LEGENDE = @v_leg_id AND ACL_CONTENU = @v_acl_contenu
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE ASSOCIATION_CONTENU_LEGENDE SET ACL_ORDRE = ACL_ORDRE - 1
					WHERE ACL_LEGENDE = @v_leg_id AND ACL_ORDRE > @v_acl_ordre
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM TYPE_AGV WHERE TAG_LEGENDE = @v_leg_id)
			UNION (SELECT 1 FROM BASE WHERE BAS_LEGENDE = @v_leg_id)
			UNION (SELECT 1 FROM ITEM WHERE ITE_LEGENDE = @v_leg_id)
			UNION (SELECT 1 FROM CHARGE WHERE CHG_LEGENDE = @v_leg_id))
		BEGIN
			DELETE ASSOCIATION_CONTENU_LEGENDE WHERE ACL_LEGENDE = @v_leg_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE LEGENDE WHERE LEG_ID = @v_leg_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

