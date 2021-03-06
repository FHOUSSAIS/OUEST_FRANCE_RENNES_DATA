SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: IHM_VUETABLEAU
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Recup des caracteriques des vues tableaux
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 14/10/2004
-- Auteur		: Guillaume DELLOYE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_VUETABLEAU]
	@v_utilisateur varchar(16)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_TABLEAU_UTILISATEUR WHERE ATU_UTILISATEUR = @v_utilisateur)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_VUE_TABLEAU_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE 
                                                               WHERE ATG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_utilisateur)
		BEGIN --Cas : pas d association vue_tableau utilisateur ni groupe => on recupere les couleurs par defaut ie directement dans vue tableau
			SELECT DISTINCT VTA_COULEUR_LIGNE_IMPAIRE as COULEUR_LIGNE_IMPAIRE, VTA_COULEUR_LIGNE_PAIRE as COULEUR_LIGNE_PAIRE, VTA_TAILLE as TAILLE
                                        FROM VUE_TABLEAU
		END
		ELSE --Cas : un enregistrement association vue_tableau groupe existe
			SELECT DISTINCT TOP 1 ATG_COULEUR_LIGNE_IMPAIRE as COULEUR_LIGNE_IMPAIRE, ATG_COULEUR_LIGNE_PAIRE as COULEUR_LIGNE_PAIRE,  ATG_TAILLE as TAILLE, AUG_PRIORITE
                                        FROM ASSOCIATION_VUE_TABLEAU_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE
                                                WHERE AUG_UTILISATEUR = @v_utilisateur
                                                      AND ATG_GROUPE = AUG_GROUPE
				ORDER BY AUG_PRIORITE
	END
	ELSE --Cas : un enregistrement association vue_tableau utilisateur existe
		SELECT ATU_COULEUR_LIGNE_IMPAIRE as COULEUR_LIGNE_IMPAIRE, ATU_COULEUR_LIGNE_PAIRE as COULEUR_LIGNE_PAIRE, ATU_TAILLE as TAILLE
		FROM ASSOCIATION_VUE_TABLEAU_UTILISATEUR
			WHERE ATU_UTILISATEUR = @v_utilisateur



