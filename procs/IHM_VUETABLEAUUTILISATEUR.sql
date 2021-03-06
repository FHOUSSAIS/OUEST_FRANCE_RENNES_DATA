SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_VUETABLEAUUTILISATEUR
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Modif des caracteristiques des vues tableaux pour un utilisateur precis
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 14/10/2004
-- Auteur		: Guillaume DELLOYE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Version/ révision	: 2.00
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_VUETABLEAUUTILISATEUR]
	@v_utilisateur varchar(16),
	@v_couleur_ligne_impaire int,
	@v_couleur_ligne_paire int,
	@v_taille tinyint,
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
	@v_old_vue_ordre tinyint,
	@vta_id int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	SELECT @vta_id = VTA_ID FROM VUE_TABLEAU
	IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_TABLEAU_UTILISATEUR WHERE ATU_UTILISATEUR = @v_utilisateur)
	BEGIN 	--insertion de l enregistrement
		INSERT INTO ASSOCIATION_VUE_TABLEAU_UTILISATEUR  
		(ATU_UTILISATEUR, ATU_VUE_TABLEAU, ATU_COULEUR_LIGNE_IMPAIRE, ATU_COULEUR_LIGNE_PAIRE, ATU_TAILLE) 
                           VALUES (@v_utilisateur, @vta_id, @v_couleur_ligne_impaire, @v_couleur_ligne_paire, @v_taille)
	END
	ELSE
	BEGIN --modification de l enregistrement
		UPDATE ASSOCIATION_VUE_TABLEAU_UTILISATEUR 
			SET ATU_VUE_TABLEAU = @vta_id,
			        ATU_COULEUR_LIGNE_IMPAIRE = @v_couleur_ligne_impaire,
			        ATU_COULEUR_LIGNE_PAIRE= @v_couleur_ligne_paire, 
			        ATU_TAILLE = @v_taille
			WHERE ATU_UTILISATEUR = @v_utilisateur
	END

	SELECT @v_error = @@ERROR
	IF @v_error = 0
		SELECT @v_retour = 0
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error




