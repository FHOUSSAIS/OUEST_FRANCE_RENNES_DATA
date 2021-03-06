SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_COLORIAGEUTILISATEUR
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_uti_id : Utilisateur
--			  @v_uti_langue : Langue
--			  @v_vue_id : Vue
--			  @v_clr_id : Règle de coloriage
--			  @v_alu_couleur : Couleur
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des règles de coloriage par utilisateur
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 26/10/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Version/ révision	: 2.00
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_COLORIAGEUTILISATEUR]
	@v_action smallint,
	@v_uti_id varchar(16),
	@v_uti_langue varchar(3),
	@v_vue_id int,
	@v_clr_id int,
	@v_alu_couleur int,
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

	SELECT @v_retour = 113
	SELECT @v_error = 0
	BEGIN TRAN
	IF @v_action IN (0, 2)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLORIAGE_UTILISATEUR WHERE ALU_UTILISATEUR = @v_uti_id AND ALU_COLORIAGE = @v_clr_id)
		BEGIN
			INSERT INTO ASSOCIATION_COLORIAGE_UTILISATEUR (ALU_UTILISATEUR, ALU_COLORIAGE, ALU_COULEUR)
				VALUES (@v_uti_id, @v_clr_id, @v_alu_couleur)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
		BEGIN
			IF @v_action = 0
				SELECT @v_retour = 0
			ELSE IF @v_action = 2
			BEGIN
				UPDATE ASSOCIATION_COLORIAGE_UTILISATEUR SET ALU_COULEUR = @v_alu_couleur
					WHERE ALU_UTILISATEUR = @v_uti_id AND ALU_COLORIAGE = @v_clr_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLORIAGE_UTILISATEUR, COLORIAGE WHERE ALU_UTILISATEUR = @v_uti_id
			AND CLR_ID = ALU_COLORIAGE AND CLR_TABLEAU = @v_vue_id)
		BEGIN
			IF EXISTS (SELECT 1 FROM ASSOCIATION_COLORIAGE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE
				WHERE ALG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id)
			BEGIN
				INSERT INTO ASSOCIATION_COLORIAGE_UTILISATEUR (ALU_UTILISATEUR, ALU_COLORIAGE, ALU_COULEUR)
					SELECT @v_uti_id, CLR_ID, MIN(ALG_COULEUR) FROM COLORIAGE, ASSOCIATION_COLORIAGE_GROUPE,
						ASSOCIATION_UTILISATEUR_GROUPE WHERE CLR_TABLEAU = @v_vue_id AND ALG_COLORIAGE = CLR_ID
						AND ALG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id
						GROUP BY CLR_ID
				SELECT @v_error = @@ERROR
			END
			ELSE
			BEGIN
				INSERT INTO ASSOCIATION_COLORIAGE_UTILISATEUR (ALU_UTILISATEUR, ALU_COLORIAGE, ALU_COULEUR)
					SELECT @v_uti_id, CLR_ID, CLR_COULEUR FROM COLORIAGE WHERE CLR_TABLEAU = @v_vue_id
				SELECT @v_error = @@ERROR
			END
		END
		IF @v_error = 0
		BEGIN
			DELETE ASSOCIATION_COLORIAGE_UTILISATEUR WHERE ALU_UTILISATEUR = @v_uti_id AND ALU_COLORIAGE = @v_clr_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error


